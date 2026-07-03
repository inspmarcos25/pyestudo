// Roda dentro de um Web Worker: uma thread real do sistema operacional,
// separada da thread principal do navegador (onde o app Flutter roda).
//
// Isso é o que permite interromper de verdade uma execução travada (ex.:
// `while True: pass`): Worker.terminate() mata a thread instantaneamente,
// sem qualquer cooperação do código em execução — e, crucial, o laço
// travado nunca congela a aba, porque roda numa thread separada da
// interface. Um <iframe> não garante isso: iframes da mesma origem
// compartilham a thread JS da página principal.
importScripts('pyodide.js');

let pyodide;

async function boot() {
  try {
    // Fetch relativo a este arquivo (assets/pyodide/worker.js).
    const runnerSource = await (await fetch('../python/runner.py')).text();
    pyodide = await loadPyodide({ indexURL: './' });
    pyodide.setStdout({ batched: (s) => postMessage({ channel: 'PyStdout', data: s + '\n' }) });
    pyodide.setStderr({ batched: (s) => postMessage({ channel: 'PyStdout', data: s + '\n' }) });
    pyodide.runPython(runnerSource);
    postMessage({ channel: 'PyReady', data: 'ok' });
  } catch (e) {
    postMessage({ channel: 'PyReady', data: String(e) });
  }
}

self.onmessage = async (event) => {
  const { kind, requestId, a, b } = event.data;
  try {
    let resultJson;
    if (kind === 'run') {
      await pyodide.loadPackagesFromImports(a);
      resultJson = await pyodide.globals.get('run_user_code')(a, b || '');
    } else if (kind === 'tests') {
      await pyodide.loadPackagesFromImports(a);
      resultJson = await pyodide.globals.get('run_with_tests')(a, b);
    } else {
      throw new Error('kind desconhecido: ' + kind);
    }
    postMessage({ channel: 'PyResult', data: JSON.stringify({ requestId, resultJson }) });
  } catch (e) {
    const errorJson = JSON.stringify({
      ok: false, needInput: false, stdout: '',
      error: { type: 'RuntimeHostError', message: String(e), line: null, traceback: '' },
    });
    postMessage({ channel: 'PyResult', data: JSON.stringify({ requestId, resultJson: errorJson }) });
  }
};

boot();
