Write-Host "Installing freezer"

$pc_name = whoami

# Get Administrator password
$password = Read-Host 'Administrator password is required to install freezer-scheduler as a windows service, please type in your password' -AsSecureString
$password_check = Read-Host 'Please type your password again' -AsSecureString

$plain_password = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))

$plain_password_check = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($password_check))

If (-Not($plain_password -eq $plain_password_check)) {
  echo "WARNING"
  echo "Passwords do not match"
  Exit
}

function Install-Chocoloate {
  iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))
}

function Download-Dependencies {
  powershell -Command "(New-Object Net.WebClient).DownloadFile('https://www.python.org/ftp/python/2.7.11/python-2.7.11rc1.msi', 'python.msi')"
  powershell -Command "(New-Object Net.WebClient).DownloadFile('https://download.microsoft.com/download/7/9/6/796EF2E4-801B-4FC4-AB28-B59FBF6D907B/VCForPython27.msi', 'compiler.msi')"
  powershell -Command "(New-Object Net.WebClient).DownloadFile('https://download.sysinternals.com/files/Sync.zip', 'sync.zip')"
}

function Reload-Path {
  $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

Install-Chocoloate
choco install git.install -yfd
choco install openssl.light -yfd
choco install 7zip.commandline -yfd

Download-Dependencies

msiexec /i python.msi /quiet
msiexec /i compiler.msi /quiet

cmd /c 7z e sync.zip
New-Item -ItemType Directory -Force -Path C:\Sync
# copy sync.exe to C:\Sync
xcopy /s sync.exe C:\Sync /Y

# add paths
$path = $env:Path
setx /M PATH $path";C:\Python27;C:\Python27\Scripts;C:\Python27\Lib\site-packages;C:\Program Files\Git;C:\Program Files\Git\cmd;C:\Program Files\Git\bin;C:\Program Files\OpenSSL\bin;C:\Sync"

Reload-Path

# installing pywin32
pip install https://pypi.python.org/packages/cp27/p/pypiwin32/pypiwin32-219-cp27-none-win32.whl

# Installing freezer
git clone https://github.com/openstack/freezer.git C:\freezer
Set-Location -Path C:\freezer
git pull origin master
pip install -r requirements.txt
python setup.py install
git clone https://github.com/memogarcia/freezer-windows-binaries C:\Python27\Lib\site-packages\freezer\bin

# deploying scheduler
Set-Location -Path C:\freezer\freezer\scheduler
python win_service.py --username $pc_name --password $plain_password install
