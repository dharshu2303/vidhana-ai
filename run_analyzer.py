import subprocess
try:
    result = subprocess.run(['flutter.bat', 'analyze'], cwd='fir_app', capture_output=True, text=True, shell=True)
    with open('analyzer_output.txt', 'w', encoding='utf-8') as f:
        f.write(result.stdout)
        f.write('\n========= STDERR =========\n')
        f.write(result.stderr)
        f.write(f'\nReturn code: {result.returncode}')
except Exception as e:
    with open('analyzer_output.txt', 'w', encoding='utf-8') as f:
        f.write(f'Exception: {str(e)}')
