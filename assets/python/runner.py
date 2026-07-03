"""Executa o código do aluno e captura stdout + erros com número de linha.

Roda dentro do Pyodide (ou de qualquer CPython embarcado). O código do aluno
é compilado com o filename sentinela "<exercicio>"; em caso de erro, a linha
reportada é a do último frame pertencente a esse arquivo.
"""

import io
import json
import linecache
import sys
import traceback
import warnings

USER_FILE = "<exercicio>"

# Silencia avisos ruidosos de bibliotecas (ex.: pandas sobre pyarrow) para
# não poluir o console do aluno. Erros de verdade continuam aparecendo.
warnings.simplefilter("ignore", DeprecationWarning)
warnings.simplefilter("ignore", FutureWarning)


def _register_source(source: str) -> None:
    """Registra o código no linecache para que inspect.getsource() funcione.

    Sem isso, testes que inspecionam o código do aluno (ex.: verificar que
    não usou max()) falham com OSError, pois o código roda via exec() sem
    arquivo no disco.
    """
    linecache.cache[USER_FILE] = (
        len(source),
        None,
        source.splitlines(keepends=True),
        USER_FILE,
    )


class _NeedInput(Exception):
    """O programa pediu input() e não há mais linhas: a UI coleta e reexecuta."""


def _make_input(stdin_text: str):
    """input() que consome as respostas já dadas; sem resposta, sinaliza a UI.

    Ecoa o prompt e a resposta no stdout, como um terminal faria.
    """
    buffer = io.StringIO(stdin_text)

    def _input(prompt=""):
        print(prompt, end="")
        line = buffer.readline()
        if not line:
            raise _NeedInput()
        line = line.rstrip("\n")
        print(line)
        return line

    return _input


def run_user_code(source: str, stdin_text: str = "") -> str:
    """Retorna JSON: {ok, needInput, stdout, error: {type, message, line, traceback} | null}.

    needInput=True: o stdout termina no prompt do input() pendente; o app
    mostra um campo no console, acrescenta a resposta ao stdin e reexecuta.
    """
    out = io.StringIO()
    result = {"ok": True, "needInput": False, "stdout": "", "error": None}
    old_out, old_err = sys.stdout, sys.stderr
    sys.stdout = sys.stderr = out
    try:
        code = compile(source, USER_FILE, "exec")
        exec(code, {"__name__": "__main__", "input": _make_input(stdin_text)})
    except _NeedInput:
        result["ok"] = False
        result["needInput"] = True
    except SyntaxError as e:
        result["ok"] = False
        result["error"] = {
            "type": "SyntaxError",
            "message": e.msg,
            "line": e.lineno,
            "traceback": traceback.format_exc(),
        }
    except BaseException as e:
        line = None
        for frame in traceback.extract_tb(e.__traceback__):
            if frame.filename == USER_FILE:
                line = frame.lineno  # o frame mais profundo do aluno prevalece
        result["ok"] = False
        result["error"] = {
            "type": type(e).__name__,
            "message": str(e),
            "line": line,
            "traceback": traceback.format_exc(),
        }
    finally:
        sys.stdout, sys.stderr = old_out, old_err
    result["stdout"] = out.getvalue()
    return json.dumps(result)


def run_with_tests(source: str, tests_json: str) -> str:
    """Executa o código do aluno e depois cada teste; retorna JSON com resultados.

    tests_json: [{"name": str, "code": str}, ...] — cada code roda no mesmo
    namespace do código do aluno (asserts simples).
    """
    def _no_input(prompt=""):
        raise EOFError("input() não é suportado na verificação de exercícios")

    tests = json.loads(tests_json)
    results = []
    namespace = {"__name__": "__main__", "input": _no_input}
    _register_source(source)
    out = io.StringIO()
    old_out, old_err = sys.stdout, sys.stderr
    sys.stdout = sys.stderr = out
    try:
        try:
            exec(compile(source, USER_FILE, "exec"), namespace)
        except BaseException as e:
            sys.stdout, sys.stderr = old_out, old_err
            # código do aluno nem roda: todos os testes falham com o erro
            msg = f"{type(e).__name__}: {e}"
            return json.dumps(
                {"setupError": msg,
                 "tests": [{"name": t["name"], "passed": False, "message": msg}
                           for t in tests]})
        for t in tests:
            try:
                exec(compile(t["code"], "<teste>", "exec"), namespace)
                results.append({"name": t["name"], "passed": True, "message": ""})
            except AssertionError as e:
                results.append({"name": t["name"], "passed": False,
                                "message": str(e) or "resultado diferente do esperado"})
            except BaseException as e:
                results.append({"name": t["name"], "passed": False,
                                "message": f"{type(e).__name__}: {e}"})
    finally:
        sys.stdout, sys.stderr = old_out, old_err
    return json.dumps({"setupError": None, "tests": results})
