# Get username and password
echo "Freezer windows installer v0.1"
$pc_name = whoami
$password = Read-Host 'Administrator password is required to install freezer-scheduler as a windows service, please type in your password' -AsSecureString
$password_check = Read-Host 'Please type your password again' -AsSecureString

$plain_password = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))

$plain_password_check = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($password_check))

If (-Not($plain_password -eq $plain_password_check))
  {
    echo "WARNING"
    echo "Passwords do not match"
    Exit
  }

# Installing chocolate
iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))

# Installing python
choco install python2 -y

# Installing git
choco install git -y

# Installing openssl
choco install openssl.light -y

# Installing pywin32
easy_install http://downloads.sourceforge.net/project/pywin32/pywin32/Build%20219/pywin32-219.win32-py2.7.exe

# Installing Microsoft Visual C++ Compiler for Python 2.7
powershell -Command "(New-Object Net.WebClient).DownloadFile('https://download.microsoft.com/download/7/9/6/796EF2E4-801B-4FC4-AB28-B59FBF6D907B/VCForPython27.msi', 'compiler.msi')"
msiexec /i compiler.msi /quiet

# Installing freezer
git clone https://github.com/openstack/freezer.git C:\freezer
Set-Location -Path C:\freezer
git pull origin master
pip install -r C:\freezer\requirements.txt
python setup.py install
git clone https://github.com/memogarcia/freezer-windows-binaries C:\Python27\Lib\site-packages\freezer\bin

# Installing sync
powershell -Command "(New-Object Net.WebClient).DownloadFile('https://download.sysinternals.com/files/Sync.zip', 'sync.zip')"
choco install 7zip.commandline -y
7z e sync.zip
New-Item -ItemType Directory -Force -Path C:\Sync
xcopy /s sync.exe C:\Sync /y
setx PATH "%PATH%;c:\Sync" /m

# Installing freezer-scheduler
Set-Location -Path C:\Python27\Lib\site-packages\freezer\scheduler
python win_service.py --username $pc_name --password $plain_password install
