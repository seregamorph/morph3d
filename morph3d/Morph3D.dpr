// Morph3D Screen Saver for Windows
// https://github.com/seregamorph/morph3d
//
// Made by Sergey Chernov
// E-mail: morph3d[at]mail.ru

program Morph3D;
uses
  Windows, Messages, ShellApi,
  MorphUn in 'MorphUn.pas',
  DrawUn in 'DrawUn.pas',
  ShapeUn in 'ShapeUn.pas';

{$E scr}

{$R *.res}
{$R dialog.res}
{$R strings.res}

type
  TVSSPFunc = function(Parent : HWND) : BOOL; stdcall;
  TPCPAFunc = function(A : PChar; Parent : HWND; B, C : Integer) : Integer; stdcall;

var
  MoveCounter : Integer=-1;
  Msg         : TMsg;
  S           : String;
  Dummy       : DWORD;
  ParentWnd   : HWND=0;
  ActiveWnd   : HWND=0;
  R           : TRect;
  OldX        : Integer=0;
  OldY        : Integer=0;

const
  AppName = 'Morph3D Screen Saver';
  RegKey = 'Software\Morph3D';

  // Checkbox "FPS"
  ID_SHOWFPS=256;

  // Checkbox "Unsort points"
  ID_UNSORT=257;

  // Checkbox "Mouse Sensivity"
  ID_MOUSESENS=258;

  // Checkbox "Move in 3D"
  ID_MOVE3D=259;

  // Checkbox "Primitive points draw"
  ID_PRIMITIVEPOINTS=262;

  // Checkbox "Hues of gray"
  ID_HUESOFGRAY=263;

  // Button e-mail
  ID_MAIL=260;

  // Button site
  ID_SITE=261;

  ID_TRACE=264;

  ID_TRACEMODECOMBO=265;

  ID_TRACELENGTH=266;

  ID_TRACELENGTHLAB=267;

  TBM_GETPOS      = WM_USER;
  TBM_SETPOS      = WM_USER+5;
  TBM_SETRANGEMIN = WM_USER+7;
  TBM_SETRANGEMAX = WM_USER+8;

function StrPas(S : PChar) : String;
begin
  Result := S;
end;

procedure GetReg;
var
  hReg : HKEY;
  Buff : array[0..127] of Char;
  rt   : Integer;
  rc   : DWORD;
  function GetRegParam(RegStr : String; Default : Integer) : Integer;
  begin
    if (RegQueryValueEx(hReg, PChar(RegStr), nil, @rt, @Buff, @rc)=0) then
      Result := StrToInt(StrPas(Buff)) else
      Result := Default;
  end;
  function IntToBool(Value : Integer) : Boolean;
  begin
    if (Value=0) then Result := False else Result := True;
  end;
begin
  RegOpenKeyEx(HKEY_CURRENT_USER, RegKey, 0, KEY_ALL_ACCESS, hReg);

  FillChar(Buff, SizeOf(Buff), #0);
  rt := REG_SZ; rc := 2;

  ShowFPS         := IntToBool(GetRegParam('ShowFPS', 0));
  UnSortPoints    := IntToBool(GetRegParam('UnSortPoints', 0));
  MouseSens       := IntToBool(GetRegParam('MouseSens', 1));
  Move3D          := IntToBool(GetRegParam('Move3D', 0));
  PrimitivePoints := IntToBool(GetRegParam('PrimitivePoints', 1));
  HuesOfGray      := IntToBool(GetRegParam('HuesOfGray', 0));
  Trace           := IntToBool(GetRegParam('Trace', 1));
  TraceModeInd    := GetRegParam('TraceModeInd', 2);
  TraceLength     := GetRegParam('TraceLength', 1);

  RegCloseKey(hReg);
end;

procedure Regist;
var
  hReg : HKEY;
  rt   : Cardinal;
  Str  : String;
  procedure SetRegParam(RegStr : String; Value : Integer);
  begin
    Str := IntToStr(Value);
    RegSetValueEx(hReg, PChar(RegStr), 0, rt, PChar(Str), Length(Str));
  end;
begin
  rt := REG_SZ;
  if (RegOpenKeyEx(HKEY_CURRENT_USER, RegKey, 0, KEY_ALL_ACCESS, hReg) <> 0) then
    RegCreateKey(HKEY_CURRENT_USER, RegKey, hReg);

  SetRegParam('ShowFPS', Integer(ShowFPS));
  SetRegParam('UnSortPoints', Integer(UnSortPoints));
  SetRegParam('MouseSens', Integer(MouseSens));
  SetRegParam('Move3D', Integer(Move3D));
  SetRegParam('PrimitivePoints', Integer(PrimitivePoints));
  SetRegParam('HuesOfGray', Integer(HuesOfGray));
  SetRegParam('Trace', Integer(Trace));
  SetRegParam('TraceModeInd', TraceModeInd);
  SetRegParam('TraceLength', TraceLength);

  RegCloseKey(hReg);
end;

procedure SetPassword;
var
  Lib  : THandle;
  Func : TPCPAFunc;
begin
  Lib := LoadLibrary('MPR.DLL');
  if (Lib > 32) then
  begin
    @Func := GetProcAddress(Lib, 'PwdChangePasswordA');
    if (@Func <> nil) then Func('SCRSAVE', StrToInt(ParamStr(2)), 0, 0);
    FreeLibrary(Lib);
  end;
end;

function CheckPassword : Boolean;
var
  Key    : HKEY;
  D1, D2 : Integer;
  Value  : Integer;
  Lib    : THandle;
  Func   : TVSSPFunc;
begin
  Result := True;
  if (Preview) then Exit;
  if (RegOpenKeyEx(HKEY_CURRENT_USER, 'Control Panel\Desktop', 0, Key_Read,
    Key) = Error_Success) then                     
  begin
    D2 := SizeOf(Value);
    if (RegQueryValueEx(Key, 'ScreenSaveUsePassword', nil, @D1, @Value, @D2) =
      Error_Success) then
    begin
      if (Value <> 0) then
      begin
        Lib := LoadLibrary('PASSWORD.CPL');
        if (Lib > 32) then
        begin
          @Func := GetProcAddress(Lib, 'VerifyScreenSavePwd');
          DoDraw := False; ShowCursor(True);
          if (@Func <> nil) then Result := Func(hWindow);
          ShowCursor(False); DoDraw := True;
          MoveCounter := 0;
          FreeLibrary(Lib);
        end;
      end;
    end;
    RegCloseKey(Key);
  end;
end;

function About(Dialog : HWND; AMessage, WParam : UINT;
  LParam : LPARAM) : Bool; stdcall; export;
  procedure AddCBString(S : String);
  begin
    SendMessage(GetDlgItem(Dialog, ID_TRACEMODECOMBO), CB_ADDSTRING,
      0, LongInt(S));
  end;
  procedure SetTraceWndEnabled;
  begin
    EnableWindow(GetDlgItem(Dialog, ID_PRIMITIVEPOINTS), not Trace);
    EnableWindow(GetDlgItem(Dialog, ID_TRACEMODECOMBO), Trace);
    EnableWindow(GetDlgItem(Dialog, ID_TRACELENGTH), Trace);
    EnableWindow(GetDlgItem(Dialog, ID_TRACELENGTHLAB), Trace);
    if (Trace) then
    begin
      SendMessage(GetDlgItem(Dialog, ID_PRIMITIVEPOINTS), BM_SETCHECK, 1, 0);
      PrimitivePoints := True;
    end;
  end;
  procedure SetCBCheck(ID : Integer; Value : Boolean);
  begin
    SendMessage(GetDlgItem(Dialog, ID), BM_SETCHECK, Integer(Value), 0);
  end;
  function GetCBCheck(ID : Integer) : Boolean;
  begin
    Result := (SendMessage(GetDlgItem(Dialog, ID), BM_GETCHECK, 0, 0) = 1);
  end;
var
  i : Integer;
begin
  case AMessage of
    WM_INITDIALOG :
      begin
        for i := 0 to 2 do AddCBString(ResStr[i+6]);
        SendMessage(GetDlgItem(Dialog, ID_TRACELENGTH), TBM_SETRANGEMIN, 1, 0);
        SendMessage(GetDlgItem(Dialog, ID_TRACELENGTH), TBM_SETRANGEMAX, 1, 3);

        SetCBCheck(ID_SHOWFPS, ShowFPS);
        SetCBCheck(ID_UNSORT, UnSortPoints);
        SetCBCheck(ID_MOUSESENS, MouseSens);
        SetCBCheck(ID_MOVE3D, Move3D);
        SetCBCheck(ID_PRIMITIVEPOINTS, PrimitivePoints);
        SetCBCheck(ID_HUESOFGRAY, HuesOfGray);
        SetCBCheck(ID_TRACE, Trace);

        SendMessage(GetDlgItem(Dialog, ID_TRACEMODECOMBO), CB_SETCURSEL,
          TraceModeInd, 0);
        SendMessage(GetDlgItem(Dialog, ID_TRACELENGTH), TBM_SETPOS, 1,
          TRACELENGTH);

        SetTraceWndEnabled;
      end;

    WM_TIMER : InvalidateRect(hWindow, nil, False);
    WM_COMMAND :
      case WParam of
        IDOK, IDCANCEL :
        begin
          if (WParam=IDOK) then
          begin
            ShowFPS := GetCBCheck(ID_SHOWFPS);
            UnSortPoints := GetCBCheck(ID_UNSORT);
            MouseSens := GetCBCheck(ID_MOUSESENS);
            Move3D := GetCBCheck(ID_MOVE3D);
            PrimitivePoints := GetCBCheck(ID_PRIMITIVEPOINTS);
            HuesOfGray := GetCBCheck(ID_HUESOFGRAY);
            Trace := GetCBCheck(ID_TRACE);
            TraceModeInd := SendMessage(GetDlgItem(Dialog, ID_TRACEMODECOMBO),
              CB_GETCURSEL, 0, 0);
            TraceLength := SendMessage(GetDlgItem(Dialog, ID_TRACELENGTH),
              TBM_GETPOS, 0, 0);

            Regist;
          end;
          EndDialog(Dialog, 1);
        end;
        ID_MAIL : ShellExecute(0, nil, 'mailto:morph3d@mail.ru', nil, nil, SW_NORMAL);
        ID_SITE : ShellExecute(0, nil, 'https://github.com/seregamorph/morph3d', nil, nil, SW_NORMAL);
        ID_TRACE :
          begin
            Trace := (SendMessage(GetDlgItem(Dialog, ID_TRACE), BM_GETCHECK, 0, 0) = 1);
            SetTraceWndEnabled;
          end;
      end;
  end;
  Result := False;
end;

procedure Wnd_Size(Window : HWND);
type
  BMI8BPP=record
    bmiHeader : BITMAPINFOHEADER;
    bmiColor : array[0..255] of RGBQUAD;
  end;
var
  bmpinfo : BMI8BPP;
  n : Integer;
  palentryarr : array[0..255] of RGBQUAD;
begin
  DeleteObject(DC);
  DeleteObject(CDC);
  DeleteObject(DCBitmap);

  GetClientRect(Window, WndRect);
  WndWidth := WndRect.Right-WndRect.Left;
  if (WndWidth div 4 <> 0) then WndWidth := WndWidth - (WndWidth mod 4) + 4;
  WndHeight := WndRect.Bottom-WndRect.Top;
  if ((WndWidth=0) and (WndHeight=0)) then Exit;

  DC := GetDC(Window);

  CDC := CreateCompatibleDC(DC);
  if (not Trace) then
    DCBitmap := CreateCompatibleBitmap(DC, WndWidth, WndHeight) else
  begin
    bmpinfo.bmiHeader.biSize := sizeof(BITMAPINFOHEADER);
    bmpinfo.bmiHeader.biWidth := WndWidth;
    bmpinfo.bmiHeader.biHeight := -WndHeight;
    bmpinfo.bmiHeader.biPlanes := 1;
    bmpinfo.bmiHeader.biBitCount := 8;
    bmpinfo.bmiHeader.biCompression := BI_RGB;
    DCBitmap := CreateDIBSection1(DC, @bmpinfo, DIB_RGB_COLORS, bitptr, 0, 0);
  end;
  if (DCBitmap=0) or (bitptr=nil) then
  begin
    DCBitmap := CreateCompatibleBitmap(DC, WndWidth, WndHeight);
    Trace := False;
  end;
  SelectObject(CDC, DCBitmap);
  if ((Trace) and (HuesOfGray)) then
  begin
    for n := 0 to 255 do
    begin
      palentryarr[n].rgbRed := n;
      palentryarr[n].rgbGreen := n;
      palentryarr[n].rgbBlue := n;
    end;
    SetDIBColorTable(CDC, 0, 256, palentryarr);
  end;

  SetBkColor(CDC, clBlack); // screen clean
  ExtTextOut(CDC, 0, 0, ETO_OPAQUE, @WndRect, nil, 0, nil);

  SetBkColor(DC, clBlack);
  SetTextColor(DC, clWhite);

  ScrX := (WndWidth div 2);
  ScrY := (WndHeight div 2);
  CoefX := (WndWidth div 8);
  CoefY := (WndHeight div 6);

  if (not Trace) then
  begin
    VectX := VectX*1.33;
    VectY := VectY*1.33;
    VectZ := VectZ*1.33;
    VectAX := VectAX*1.33;
    VectAY := VectAY*1.33;
    VectAZ := VectAZ*1.33;
    WaitPer := WaitPer/1.33;
  end;
  Wait := WaitPer;

  LastTickCount := GetTickCount;

  InitComplete := True;
  DoDraw := True;
end;

procedure Wnd_Destroy;
begin
  if (CheckPassword) then
  begin
    QuitSaver := True;

    DeleteObject(DCBitmap);
    DeleteObject(CDC);
    ReleaseDC(hWindow, DC);
    DoDraw := False;

    PostQuitMessage(0);
  end;
end;

function WindowProc(Window : HWND; AMessage, WParam,
  LParam : Longint) : Longint; stdcall; export;
var
  X, Y : Integer;
begin
  case AMessage of
    WM_SYSCOMMAND :
      case WParam of
        SC_CLOSE : PostMessage(Window, WM_CLOSE, 0, 0);
        SC_SCREENSAVE :
          begin
            Result := 0;
            Exit;
          end;
        SC_KEYMENU : PostMessage(Window, WM_CLOSE, 0, 0);
      end;

    WM_CREATE :
      begin
        SecStart := GetTickCount;

        InitShape(PCoords1);
        InitShape(PCoords2);

        CalcPos;
      end;
    WM_DESTROY : Wnd_Destroy;

    WM_KEYDOWN,
//    WM_MOUSEWHEEL,
    WM_LBUTTONDOWN, WM_RBUTTONDOWN : if (not Preview) then
      PostMessage(Window, WM_CLOSE, 0, 0);
    WM_MOUSEMOVE :
      if ((not Preview) and (MouseSens)) then
      begin
        SetWindowPos(hWindow, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE or
          SWP_NOSIZE or SWP_NOACTIVATE);

        Inc(MoveCounter);

        X := LoWord(LParam);
        Y := HiWord(LParam);

        if (MoveCounter > 0) then
        begin
          if (sqrt(sqr(X-OldX) + sqr(Y-OldY)) > 1) then
            PostMessage(Window, WM_CLOSE, 0, 0);
        end;

        OldX := X;
        OldY := Y;

        ShowCursor(False);
      end;

    WM_PAINT : if (DoDraw) then UpdateDisplay;
    WM_NCDESTROY : DoDraw := False;
    WM_KILLFOCUS : PostMessage(Window, WM_CLOSE, 0, 0);
    WM_SETFOCUS : if (InitComplete) then DoDraw := True;
    WM_SIZE : Wnd_Size(Window);
  end;

  Result := DefWindowProc(Window, AMessage, WParam, LParam);
end;

function DoRegister : Boolean;
var
  WndClass : TWndClass;
begin
  WndClass.style := CS_HREDRAW or CS_VREDRAW;
  WndClass.lpfnWndProc := @WindowProc;
  WndClass.cbClsExtra := 0;
  WndClass.cbWndExtra := 0;
  WndClass.hInstance := HInstance;
  WndClass.hIcon := LoadIcon(HInstance, 'MAINICON');
  WndClass.hCursor := 0;
  WndClass.hbrBackground := GetStockObject(NULL_BRUSH);
  WndClass.lpszMenuName := nil;
  WndClass.lpszClassName := AppName;

  Result := (RegisterClass(WndClass) <> 0);
end;

var
  Buff : array[0..127] of Char;
  n : Integer;
begin
  Randomize;

  // Loading string resources
  for n := 1 to ResStrCount do
  begin
    LoadString(hInstance, n, Buff, SizeOf(Buff));
    ResStr[n] := StrPas(Buff);
  end;

  S := ParamStr(1);
  if (Length(S)>1) then Delete(S, 1, 1);

  ParentWnd := 0;

  GetReg;

  if (S='A') or (S='a') then SetPassword else
  if ((S='S') or (S='s')) or ((S='P') or (S='p')) then
  begin
    if (FindWindow(AppName, AppName)<>0) then Exit;

    if (not DoRegister) then
    begin
      MessageBox(0, PChar(ResStr[2]), AppName, MB_OK or MB_ICONERROR);
      //'Unable to Register Window Class!'
      Exit;
    end;

    if ((S='P') or (S='p')) then // preview mode
    begin
      ParentWnd := StrToInt(ParamStr(2));
      GetWindowRect(ParentWnd, R);
      Preview := True;
    end;
    if (not Preview) then
    begin
      ActiveWnd := GetActiveWindow;
      if (ActiveWnd=FindWindow('Shell_TrayWnd', nil)) then ActiveWnd := 0;

      hWindow := CreateWindowEx(WS_EX_TOOLWINDOW, AppName, AppName, WS_POPUP,
        0, 0, R.Right-R.Left, R.Bottom-R.Top, ParentWnd, 0, HInstance, nil);
    end else
      hWindow := CreateWindow(AppName, AppName,
        WS_CHILD or WS_VISIBLE or WS_DISABLED, 0, 0, R.Right-R.Left,
        R.Bottom-R.Top, ParentWnd, 0, HInstance, nil);

    if (hWindow = 0) then
    begin
      MessageBox(0, PChar(ResStr[3]), AppName, MB_OK or MB_ICONERROR);
      // 'Unable to Create a Window!'
      Exit;
    end;

    if (not Preview) then
    begin
      ShowCursor(False);
      ShowWindow(hWindow, SW_SHOWMAXIMIZED);
      SetWindowPos(hWindow, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE or
        SWP_NOSIZE or SWP_NOACTIVATE);
    end else ShowWindow(hWindow, SW_SHOWNORMAL);

    UpdateWindow(hWindow);

    CreateThread(nil, 0, @PreviewThreadProc, nil, 0, Dummy);

    if (not Preview) then
      SystemParametersInfo(SPI_SCREENSAVERRUNNING, 1, @Dummy, 0);

    while GetMessage(Msg, 0, 0, 0) do
    begin
      TranslateMessage(Msg);
      DispatchMessage(Msg);
    end;

    SystemParametersInfo(SPI_SCREENSAVERRUNNING, 0, @Dummy, 0);
  end else
  begin
    if (Length(S)>0) then
    if ((S[1]='c') or (S[1]='C')) then
      ParentWnd := StrToInt(Copy(S, 3, Length(S)-2));
    DialogBox(HInstance, PChar(ResStr[5]), ParentWnd, @About);
  end;
  SetActiveWindow(ActiveWnd);
end.
