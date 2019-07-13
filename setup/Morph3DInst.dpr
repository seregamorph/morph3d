program Morph3DInst;

uses
  Windows, Messages, CommDlg, ShlObj, ActiveX;

{$R *.res}
{$R res.res}
{$R Strings.res}

function WriteFile1(hFile: THandle; Buffer : Pointer; nNumberOfBytesToWrite: DWORD;
  var lpNumberOfBytesWritten: DWORD; lpOverlapped: POverlapped): BOOL; stdcall;
  external kernel32 name 'WriteFile';

const
  ResStrCount = 34;
  AppName = 'Morph3D Screen Saver Setup';
  ResType = 'SE';
  WndWidth = 525;
  WndHeight = 305;
var
  hWindow : hWnd;
  hStatic, hStaticPath,
  hStatic1, hStatic2,
  hStaticCopy1, hStaticCopy2,
  hPrevBtn, hInstBtn, hBrowseBtn,
  hCancelBtn, hPathEdit,
  hLicenseEdit, hCheckButton : hWnd;
  Msg : TMsg;
  WinDir, PFDir, MMPDir : String;
  Ok : Boolean;
  ResStr : array[1..ResStrCount] of String;
  n : Integer;
  Buff : array[0..127] of Char;
  InstallComplete : Boolean=False;
  PageInd : Integer=0;
  ScrWidth, ScrHeight : Integer;

  HLResInfo, HLGlobal : THandle;
  PLicense : PChar;

function StrPas(S : PChar) : String;
begin
  Result := S;
end;

function IntToStr(Value : Cardinal) : String;
var
  Int : Integer;
begin
  Value := abs(Value);
  Result := '';
  repeat
    Int := Value mod 10;
    Value := Value div 10;
    Result := Chr(Int+48)+Result;
  until Value = 0;
end;

procedure OleCheck(Result: HResult);
begin
  if (not Succeeded(Result)) then;//OleError(Result);
end;

function CreateComObject(const ClassID: TGUID): IUnknown;
begin
  OleCheck(CoCreateInstance(ClassID, nil, CLSCTX_INPROC_SERVER or
    CLSCTX_LOCAL_SERVER, IUnknown, Result));
end;

procedure CreateLink(const PathObj, PathLink, Desc, Param, WorkDir : string);
var
  IObject: IUnknown;
  SLink: IShellLink;
  PFile: IPersistFile;
begin
  SetWindowText(hStaticCopy2, PChar(PathLink));

  IObject := CreateComObject(CLSID_ShellLink);
  SLink := IObject as IShellLink;
  PFile := IObject as IPersistFile;
  with SLink do
  begin
    SetArguments(PChar(Param));
    SetDescription(PChar(Desc));
    SetPath(PChar(PathObj));
    SetWorkingDirectory(PChar(WorkDir));
  end;
  PFile.Save(PWChar(WideString(PathLink)), FALSE);
end;

procedure GetReg;
const
  RegKey98 = 'SOFTWARE\Microsoft\Windows\CurrentVersion';
  RegKeyNT = 'SOFTWARE\Microsoft\Windows NT\CurrentVersion';
  RegKeyMMPDir = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders';
var
  hReg : HKEY;
  Buff : array[0..127] of Char;
  rt   : Integer;
  rc   : DWORD;
begin
  RegOpenKeyEx(HKEY_LOCAL_MACHINE, RegKey98, 0, KEY_QUERY_VALUE, hReg);
  FillChar(Buff, SizeOf(Buff), #0);
  rt := REG_SZ; rc := 127;
  if (RegQueryValueEx(hReg, 'ProgramFilesDir', nil, @rt, @Buff, @rc)=0) then
    if (rc>0) then PFDir := (StrPas(Buff));
  RegCloseKey(hReg);

  GetWindowsDirectory(Buff, SizeOf(Buff));
  WinDir := StrPas(Buff);

  RegOpenKeyEx(HKEY_CURRENT_USER, RegKeyMMPDir, 0, KEY_QUERY_VALUE, hReg);
  FillChar(Buff, SizeOf(Buff), #0);
  rt := REG_SZ; rc := 127;
  if (RegQueryValueEx(hReg, 'Programs', nil, @rt, @Buff, @rc)=0) then
    if (rc>0) then MMPDir := (StrPas(Buff));
  RegCloseKey(hReg);
end;

procedure Regist(InstallDir : String);
var
  hReg : HKEY;
  rt   : Cardinal;
  UnInstStr : String;
const
  RegKey = 'SOFTWARE\Morph3D';
  UnInstKey = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Morph3D Screen Saver';
begin
  rt := REG_SZ;
  if (RegOpenKeyEx(HKEY_CURRENT_USER, RegKey, 0, KEY_ALL_ACCESS, hReg) <> 0) then
    RegCreateKey(HKEY_CURRENT_USER, RegKey, hReg);
  RegSetValueEx(hReg, 'InstallDir', 0, rt, PChar(InstallDir), Length(InstallDir));
  RegCloseKey(hReg);

  rt := REG_SZ;
  if (RegOpenKeyEx(HKEY_LOCAL_MACHINE, UnInstKey, 0, KEY_ALL_ACCESS, hReg) <> 0) then
    RegCreateKey(HKEY_LOCAL_MACHINE, UnInstKey, hReg);
  RegSetValueEx(hReg, 'DisplayName', 0, rt, PChar('Morph3D Screen Saver v4.0'), 25);
  UnInstStr := InstallDir+'UnInst.exe';
  RegSetValueEx(hReg, 'UninstallString', 0, rt, PChar(UnInstStr), Length(UnInstStr));
  RegCloseKey(hReg);
end;

function ExtractFile(ResName, FileName : String; ShowMessage : Boolean) : Boolean;
var
  HResInfo, HGlobal : THandle;
  ResPtr : Pointer;
  ResSize : Integer;
  F : HFILE;
  BytesWritten : Cardinal;
begin
  SetWindowText(hStaticCopy2, PChar(FileName));

  Result := False;

  HResInfo := FindResource(hInstance, PChar(ResName), ResType);
  if (HResInfo = 0) then Exit;
  HGlobal := LoadResource(hInstance, HResInfo);
  if HGlobal = 0 then Exit;
  ResPtr := LockResource(HGlobal);
  ResSize := SizeOfResource(hInstance, HResInfo);

  F := CreateFile(PChar(FileName), GENERIC_WRITE, FILE_SHARE_WRITE, nil,
    CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
  BytesWritten := 0;
  Result := True;
  if (not WriteFile1(F, ResPtr, ResSize, BytesWritten, nil)) then
  begin
    Result := False;
    if (ShowMessage) then
    begin
      MessageBox(hWindow, PChar(ResStr[5]+#13+FileName), PChar(ResStr[1]),
        MB_ICONERROR or MB_OK);
      Ok := False;
    end;  
  end;
  CloseHandle(F);
end;

function WindowProc(Window : HWnd; AMessage, WParam, LParam : Longint) : Longint;
  stdcall; export;
  procedure ShowElement(Handle : HWND; Visible : Boolean);
  begin
    if (Visible) then ShowWindow(Handle, SW_NORMAL) else
      ShowWindow(Handle, SW_HIDE);
  end;
  procedure ShowFreeDiskSpace(Disk : String);
  var
    dwSectorsPerCluster, dwBytesPerSector, FreeDiskSpace,
    dwNumberOfFreeClusters, dwTotalNumberOfClusters : Cardinal;
    Str : String;
  begin
    GetDiskFreeSpace(PChar(Disk), dwSectorsPerCluster, dwBytesPerSector,
      dwNumberOfFreeClusters, dwTotalNumberOfClusters);
    FreeDiskSpace := dwSectorsPerCluster*dwBytesPerSector*dwNumberOfFreeClusters div 1024;
    Str := IntToStr(FreeDiskSpace);
    SetWindowText(hStatic2, PChar(ResStr[19]+Str+ResStr[20]));
  end;
var
  Buff : array[0..127] of Char;
  BI : BrowseInfo;
  PIIDL : PItemIDList;
  InstallDir : String;
  hMenuHandle : HMENU;

  Morph3DFName : String;
begin
  case AMessage of
    WM_CREATE :
      begin
        hMenuHandle := GetSystemMenu(Window, False);
        if (hMenuHandle <> 0) then DeleteMenu(hMenuHandle, SC_CLOSE, MF_BYCOMMAND);
      end;
    WM_DESTROY : PostQuitMessage(0);
    WM_SHOWWINDOW : SetWindowText(hPathEdit, PChar(PFDir+'\Morph3D Screen Saver'));
    WM_COMMAND :
      if (LParam=(Longint(hCancelBtn))) then
      begin
        if (MessageBox(Window, PChar(ResStr[17]), PChar(ResStr[1]),
          MB_YESNO or MB_ICONQUESTION or MB_DEFBUTTON2) = IDYES) then PostMessage(Window, WM_CLOSE, 0, 0);
      end else
      if (LParam=(Longint(hBrowseBtn))) then
      begin
        BI.hwndOwner := hWindow;
        BI.pidlRoot := nil;
        BI.pszDisplayName := nil;
        BI.lpszTitle := PChar(ResStr[4]);
        BI.ulFlags := BIF_RETURNONLYFSDIRS;
        BI.lpfn := nil;
        BI.lParam := 0;
        BI.iImage := 0;
        PIIDL := SHBrowseForFolder(BI);
        if (PIIDL<>nil) then
        begin
          SHGetPathFromIDList(PIIDL, Buff);
          InstallDir := StrPas(Buff);
          if (InstallDir[Length(InstallDir)]<>'\') then
            InstallDir := InstallDir +'\';
          SetWindowText(hPathEdit, PChar(InstallDir+'Morph3D Screen Saver'));
          GetWindowText(hPathEdit, Buff, SizeOf(Buff));
          ShowFreeDiskSpace(Copy(StrPas(Buff), 1, 2));
        end;
      end else
      if ((LParam=(Longint(hInstBtn))) or (LParam=(Longint(hPrevBtn)))) then
      begin
        if (LParam=(Longint(hInstBtn))) then Inc(PageInd) else Dec(PageInd);

        EnableWindow(hPrevBtn, (PageInd>0));
        EnableWindow(hInstBtn, (PageInd<2));

        ShowElement(hLicenseEdit, (PageInd=0));
        ShowElement(hCheckButton, (PageInd=0));
        ShowElement(hStatic,      (PageInd=0));
        ShowElement(hStaticPath,  (PageInd=1));
        ShowElement(hPathEdit,    (PageInd=1));
        ShowElement(hBrowseBtn,   (PageInd=1));
        ShowElement(hStatic1,     (PageInd=1));
        ShowElement(hStatic2,     (PageInd=1));
        ShowElement(hStaticCopy1, (PageInd=2));
        ShowElement(hStaticCopy2, (PageInd=2));

        if (PageInd=1) then
        begin
          GetWindowText(hPathEdit, Buff, SizeOf(Buff));
          ShowFreeDiskSpace(Copy(StrPas(Buff), 1, 2));
        end;

        if (PageInd=2) then
        begin
          GetWindowText(hPathEdit, Buff, SizeOf(Buff));
          InstallDir := StrPas(Buff);
          if (InstallDir<>'') then
          begin
            if (InstallDir[Length(InstallDir)]<>'\') then
              InstallDir := InstallDir +'\';
            Ok := True;

            SetWindowText(hStaticCopy1, PChar(ResStr[21]));
            CreateDirectory(PChar(InstallDir), nil);
            if (not ExtractFile('Morph3D_scr', WinDir+'\Morph3D.scr', False)) then
            begin
              ExtractFile('Morph3D_scr', InstallDir+'Morph3D.scr', True);
              Morph3DFName := InstallDir+'Morph3D.scr';
            end else Morph3DFName := WinDir+'\Morph3D.scr';

            ExtractFile(ResStr[32], InstallDir+'Morph3D.htm', True);
            ExtractFile(ResStr[33], InstallDir+'License.txt', True);
            ExtractFile(ResStr[34], InstallDir+'Homepage.url', True);
            ExtractFile('UnInst_exe', InstallDir+'UnInst.exe', True);

            SetWindowText(hStaticCopy1, PChar(ResStr[26]));
            CreateDirectory(PChar(MMPDir+'\Morph3D Screen Saver'), nil);
            CoInitialize(nil);
            CreateLink(Morph3DFName, MMPDir+
              '\Morph3D Screen Saver\Morph3D Screen Saver.lnk',
              'Morph3D Screen Saver', '', WinDir);
            CreateLink(InstallDir+'Morph3D.htm', MMPDir+'\Morph3D Screen Saver\'+
              ResStr[22]+'.lnk', ResStr[22], '', Copy(InstallDir, 1, Length(InstallDir)-1));
            CreateLink(InstallDir+'License.txt', MMPDir+'\Morph3D Screen Saver\'+
              ResStr[23]+'.lnk', ResStr[23], '', Copy(InstallDir, 1, Length(InstallDir)-1));
            CreateLink(InstallDir+'Homepage.url', MMPDir+'\Morph3D Screen Saver\'+
              ResStr[24]+'.lnk', ResStr[24], '', Copy(InstallDir, 1, Length(InstallDir)-1));
            CreateLink(InstallDir+'UnInst.exe', MMPDir+'\Morph3D Screen Saver\'+
              ResStr[25]+'.lnk', ResStr[25], '', Copy(InstallDir, 1, Length(InstallDir)-1));
              
            if (Ok) then
            begin
              Regist(InstallDir);
              MessageBox(Window, PChar(ResStr[6]),
                PChar(ResStr[1]), MB_ICONINFORMATION or MB_OK);
            end else
              MessageBox(Window, PChar(ResStr[7]), PChar(ResStr[1]), MB_ICONERROR or MB_OK);

            PostQuitMessage(0);
          end else MessageBox(Window, PChar(ResStr[8]), PChar(ResStr[1]),
            MB_ICONWARNING or MB_OK);
        end;
    end else if (LParam=(Longint(hCheckButton))) then
    begin
      EnableWindow(hInstBtn, (SendMessage(hCheckButton, BM_GETCHECK, 0, 0)=1));
    end;
  end;
  Result := DefWindowProc(Window, AMessage, WParam, LParam);
end;

function RegisterWndClass : Boolean;
var
  WndClass : TWndClass;
begin
  WndClass.style := CS_HREDRAW or CS_VREDRAW;
  WndClass.lpfnWndProc := @WindowProc;
  WndClass.cbClsExtra := 0;
  WndClass.cbWndExtra := 0;
  WndClass.hInstance := hInstance;
  WndClass.hIcon := LoadIcon(HInstance, 'MAINICON');
  WndClass.hCursor := LoadCursor(0, IDC_ARROW);
  WndClass.hbrBackground := 5;
  WndClass.lpszMenuName := nil;
  WndClass.lpszClassName := AppName;
  Result := (windows.RegisterClass(WndClass) <> 0);
end;

begin
  GetReg;
  for n := 1 to ResStrCount do
  begin
    LoadString(hInstance, n, Buff, SizeOf(Buff));
    ResStr[n] := StrPas(Buff);
  end;

  HLResInfo := FindResource(hInstance, PChar(ResStr[33]), 'SE');
  HLGlobal := LoadResource(hInstance, HLResInfo);
  PLicense := PChar(LockResource(HLGlobal));

  if (not RegisterWndClass) then
  begin
    MessageBox(0, PChar(ResStr[2]), '', MB_OK);
    Exit;
  end;

  ScrWidth := GetSystemMetrics(SM_CXSCREEN);
  ScrHeight := GetSystemMetrics(SM_CYSCREEN);

  hWindow := CreateWindow(AppName, PChar(ResStr[1]), WS_OVERLAPPED or WS_SYSMENU or
    WS_MINIMIZEBOX, ((ScrWidth-WndWidth) div 2), ((ScrHeight-WndHeight) div 2),
    WndWidth, WndHeight, 0, 0, HInstance, nil);
  if (hWindow = 0) then
  begin
    MessageBox(0, PChar(ResStr[3]), '', MB_OK);
    Exit;
  end;

  hStatic := CreateWindowEx(WS_EX_TRANSPARENT, 'static', PChar(ResStr[13]), WS_CHILD or WS_VISIBLE or
    SS_LEFT, 10, 6, 300, 20, hWindow, 0, HInstance, nil);
  hStaticPath := CreateWindowEx(WS_EX_TRANSPARENT, 'static', PChar(ResStr[9]), WS_CHILD or
    SS_LEFT, 10, 70, 300, 20, hWindow, 0, HInstance, nil);
  hStatic1 := CreateWindowEx(WS_EX_TRANSPARENT, 'static', PChar(ResStr[18]), WS_CHILD or
    SS_LEFT, 10, 140, 300, 20, hWindow, 0, HInstance, nil);
  hStatic2 := CreateWindowEx(WS_EX_TRANSPARENT, 'static', PChar(ResStr[19]), WS_CHILD or
    SS_LEFT, 10, 160, 300, 20, hWindow, 0, HInstance, nil);
  hStaticCopy1 := CreateWindowEx(WS_EX_TRANSPARENT, 'static', nil, WS_CHILD or
    SS_LEFT, 10, 100, 300, 20, hWindow, 0, HInstance, nil);
  hStaticCopy2 := CreateWindowEx(WS_EX_TRANSPARENT, 'static', nil, WS_CHILD or
    SS_LEFT, 10, 130, 490, 100, hWindow, 0, HInstance, nil);
  hBrowseBtn := CreateWindow('button', PChar(ResStr[10]), WS_CHILD or WS_TABSTOP,
    395, 100, 100, 22, hWindow, 0, HInstance, nil);
  hPathEdit := CreateWindow('edit', PLicense, WS_CHILD or WS_BORDER or
    WS_TABSTOP, 10, 100, 375, 22, hWindow, 0, HInstance, nil);
  hLicenseEdit := CreateWindow('edit', PLicense, WS_CHILD or WS_VISIBLE or WS_BORDER or
    ES_MULTILINE or ES_AUTOVSCROLL or WS_TABSTOP or ES_READONLY or WS_VSCROLL, 10, 30,
    500, 180, hWindow, 0, HInstance, nil);
  hCheckButton := CreateWindow('button', PChar(ResStr[14]), WS_CHILD or WS_VISIBLE or
    BS_CHECKBOX or BS_AUTOCHECKBOX or WS_TABSTOP, 10, 215, 450, 25, hWindow, 0, HInstance, nil);
  hPrevBtn := CreateWindow('button', PChar(ResStr[15]), WS_CHILD or WS_VISIBLE or WS_TABSTOP or
    WS_DISABLED, 270, 245, 120, 25, hWindow, 0, HInstance, nil);
  hInstBtn := CreateWindow('button', PChar(ResStr[16]), WS_CHILD or WS_VISIBLE or
    BS_DEFPUSHBUTTON or WS_TABSTOP or WS_DISABLED, 390, 245, 120, 25, hWindow, 0, HInstance, nil);
  hCancelBtn := CreateWindow('button', PChar(ResStr[12]), WS_CHILD or WS_VISIBLE or WS_TABSTOP,
    10, 245, 100, 25, hWindow, 0, HInstance, nil);

  SetFocus(hLicenseEdit);

  ShowWindow(hWindow, SW_SHOWNORMAL);
  UpdateWindow(hWindow);

  while GetMessage(Msg, 0, 0, 0) do
  begin
    TranslateMessage(Msg);
    DispatchMessage(Msg);
  end;
end.
