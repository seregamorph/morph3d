unit MorphUn;

interface

uses Windows, Messages;

type
  TColor = -$7FFFFFFF-1..$7FFFFFFF;
  TByteArray = array[0..32767] of Byte;
  PByteArray = ^TByteArray;
const
  clBlack = TColor($000000);
  clWhite = TColor($FFFFFF);

  PointsCount = 240;
  ResStrCount = 8;

var
  WaitPer : Single = 6000; // Период между превращениями фигур
                           // Time between "morphing"
type
  TCoords3D = record
    X, Y, Z : Single;
  end;
  TCoords2D = record
    X, Y : Integer;
  end;
  TCoords3DArr = array[0..PointsCount-1] of TCoords3D;
  TTraceMode = (tmSimple, tmDiffuse, tmFire);
  BMI8BPP = record
    bmiHeader : BITMAPINFOHEADER;
    bmiColor : array[0..255] of RGBQUAD;
  end;

const
  TraceModeArr : array[0..2] of TTraceMode = (tmSimple, tmDiffuse, tmFire);
  FPSStrCount = 9;

function  StrToInt(S : String) : Integer;
function  IntToStr(Value : Integer) : String;
procedure UpdateDisplay;
function  XYZ(X, Y, Z : Single) : TCoords3D;
procedure AddPoint(var CoordsArr : TCoords3DArr; Coords : TCoords3D);
procedure AddPointsBetween(var CoordsArr : TCoords3DArr;
  Coords1, Coords2 : TCoords3D; Num : Integer);
procedure AddPointBetween3(var CoordsArr : TCoords3DArr;
  Coords1, Coords2, Coords3 : TCoords3D);
procedure DupPoint(var CoordsArr : TCoords3DArr);
function  PreviewThreadProc(Data : Integer) : Integer; stdcall;

function CreateDIBSection1(DC: HDC; p2: Pointer; p3: UINT;
  var p4: Pointer; p5: THandle; p6: DWORD): HBITMAP; stdcall;

var
  hWindow             : HWND;
  DoDraw              : Boolean = False;
  FrameCount          : Integer=0;
  SecStart            : Integer;
  DC, CDC             : HDC;
  DCBitmap, OldBitmap : HBITMAP;
  Rect, WndRect       : TRect;
  PIndex              : Integer=0;
  DoUp                : Boolean=True;
  Wait                : Single=0;
  Percent             : Single=0;
  WndWidth, WndHeight : Integer;

  QuitSaver           : Boolean=False;
  Preview             : Boolean=False;
  ShowFPS, UnSortPoints,
  MouseSens, Move3D,
  PrimitivePoints,
  HuesOfGray, Trace   : Boolean;
  TraceModeInd        : Integer;
  TraceLength         : Integer;

  FirstFrame          : Boolean=True;
  InitComplete        : Boolean=False;
  ResStr              : array[1..ResStrCount] of String;
  bitptr              : Pointer;

implementation

uses DrawUn, ShapeUn, Types;

function CreateDIBSection1; external gdi32 name 'CreateDIBSection';

function IntToStr(Value : Integer) : String;
var
  Int : Integer;
begin
  Result := '';
  repeat
    Int := Value mod 10;
    Value := Value div 10;
    Result := Chr(Int+48)+Result;
  until Value = 0;
end;

function StrToInt(S : String) : Integer;
var
  n : Integer;
begin
  Result := 0;
  for n := 1 to Length(S) do
  begin
    Result := Result*10;
    Result := Result + (Ord(S[N])-48);
  end;
end;

function GetFPSStr : String;
var
  TimeDelta : Integer;
begin
  TimeDelta := Trunc(GetTickCount)-SecStart;
  if (TimeDelta <> 0) then
    Result := IntToStr(Round(FrameCount/TimeDelta*1000))+ResStr[4]; // FPS
end;

function PreviewThreadProc(Data : Integer) : Integer; stdcall;
var
  STime, WTime : Cardinal;
begin
  repeat
    STime := GetTickCount;
    InvalidateRect(hWindow, nil, False);
    WTime := 0;
    if (not Trace) then
    begin
      if (30+STime>GetTickCount) then
        WTime := 30-(GetTickCount-STime);
      if (WTime<3) then WTime := 3;
      Sleep(WTime);
    end else
    begin
      if (30+STime>GetTickCount) then
        WTime := 30-(GetTickCount-STime);
      if (WTime<3) then WTime := 3;
      Sleep(WTime);
    end;
  until (QuitSaver);
  Result := 0;
end;

procedure UpdateDisplay;
var
  LastRect : TRect;
  FPSStr : String;
//  LastLeftTemp, LastRightTemp,
//  LastTopTemp, LastBottomTemp : Integer;
  dx, dy : Integer;
  PLine : PByteArray;
  pixel : Integer;
label Loop, Zero;
begin
  // перерисовка на экран
  if (not (FirstFrame or Preview or Trace)) then
    BitBlt(DC, LastLeft, LastTop, LastRight-LastLeft,
      LastBottom-LastTop, CDC, LastLeft, LastTop, SRCCOPY) else
  begin
    BitBlt(DC, WndRect.Left, WndRect.Top, WndWidth, WndHeight, CDC, 0, 0, SRCCOPY);
    FirstFrame := False;
  end;

{  if (not Trace) then
  begin
    LastLeft := LastLeftTemp;
    LastRight := LastRightTemp;
    LastTop := LastTopTemp;
    LastBottom := LastBottomTemp;
  end;}

  if (not Trace) then
  begin
    LastRect.Left := LastLeft;
    LastRect.Right := LastRight;
    LastRect.Top := LastTop;
    LastRect.Bottom := LastBottom;
  end;
  Inc(FrameCount);
  SetBkColor(CDC, clBlack); // очистка экрана / erase screen
  if (not Trace) then ExtTextOut(CDC, 0, 0, ETO_OPAQUE, @LastRect, nil, 0, nil);

  if (not Trace) then
  begin
    LastLeft := WndRect.Right;
    LastRight := WndRect.Left;
    LastTop := WndRect.Bottom;
    LastBottom := WndRect.Top;
  end;

  DrawScreen;

{  LastLeftTemp := LastLeft;
  LastRightTemp := LastRight;
  LastTopTemp := LastTop;
  LastBottomTemp := LastBottom;}

  if (not Trace) then
  begin
    if (LastRect.Left<LastLeft) then LastLeft := LastRect.Left;
    if (LastRect.Right>LastRight) then LastRight := LastRect.Right;
    if (LastRect.Top<LastTop) then LastTop := LastRect.Top;
    if (LastRect.Bottom>LastBottom) then LastBottom := LastRect.Bottom;
  end;

  TraceModeInd := (TraceModeInd mod 3);
  if (Trace) then
  case TraceModeArr[TraceModeInd] of
    tmSimple :
      begin
        for dy := 0 to WndHeight-1 do
        begin
          PLine := Pointer(LongInt(bitptr)+dy*WndWidth);
          for dx := 0 to WndWidth-1 do
          begin
            pixel := PLine^[dx]-6*(4-TraceLength);
            if (pixel<0) then PLine^[dx] := 0 else
              PLine^[dx] := pixel;
          end;
        end;
      end;
    tmDiffuse :
      begin
{       asm
          mov edi, bitptr
          mov ecx, 1024*768
          xor ax, ax
        end;
        Loop:
        asm
          mov al, [es:edi]
          cmp ax, 0
          jz Zero
          dec ax
        end;
        Zero:
        asm
          stosb
          loop Loop
        end;}

        for dy := 1 to WndHeight-2 do
        begin
          PLine := Pointer(LongInt(bitptr)+dy*WndWidth);
          for dx := 1 to WndWidth-2 do
          begin
            pixel := ((PLine^[dx-WndWidth]+PLine^[dx+WndWidth]+
              PLine^[dx-1]+PLine^[dx+1]) shr 2)-(3-TraceLength);
            if (pixel<0) then PLine^[dx] := 0 else
              PLine^[dx] := pixel;
          end;
        end;
      end;
    else
      begin
        for dy := 0 to WndHeight-3 do
        begin
          PLine := Pointer(LongInt(bitptr)+dy*WndWidth);
          for dx := 1 to WndWidth-2 do
          begin
//            pixel := ((PLine^[dx]+PLine^[dx-1]+PLine^[dx+1]+
//              PLine^[dx+WndWidth]) shr 2)-(3-TraceLength);
            pixel := ((PLine^[dx+WndWidth]+PLine^[dx+WndWidth-1]+PLine^[dx+WndWidth+1]+
              PLine^[dx+2*WndWidth]) shr 2)-(3-TraceLength);
//            pixel := ((PLine^[dx+1]+PLine^[dx-1]+PLine^[dx+WndWidth+1]+
//              PLine^[dx+WndWidth-1]) shr 2)-(3-TraceLength);
            if (pixel<0) then PLine^[dx] := 0 else
              PLine^[dx] := pixel;
          end;
        end;
      end;
  end;

{  if (not (FirstFrame or Preview or Trace)) then
    BitBlt(DC, LastLeft, LastTop, LastRight-LastLeft,
      LastBottom-LastTop, CDC, LastLeft, LastTop, SRCCOPY) else
  begin
    BitBlt(DC, WndRect.Left, WndRect.Top, WndWidth, WndHeight, CDC, 0, 0, SRCCOPY);
    FirstFrame := False;
  end;}

  if (ShowFPS) then // кадр/с / FPS
  begin
    FPSStr := GetFPSStr+'  ';
    TextOutA(DC, 10, 10, PChar(FPSStr), Length(FPSStr));
  end;
end;

function XYZ(X, Y, Z : Single) : TCoords3D;
begin
  Result.X := X;
  Result.Y := Y;
  Result.Z := Z;
end;

procedure AddPoint(var CoordsArr : TCoords3DArr; Coords : TCoords3D);
begin
  if ((0<=PIndex) and (PIndex<=PointsCount-1)) then
    CoordsArr[PIndex] := Coords;
  Inc(PIndex);
end;

procedure DupPoint(var CoordsArr : TCoords3DArr);
begin
  AddPoint(CoordsArr, CoordsArr[0]);
end;

procedure AddPointsBetween(var CoordsArr : TCoords3DArr;
  Coords1, Coords2 : TCoords3D; Num : Integer);
var
  n : Integer;
  Coords : TCoords3D;
begin
  if (Num <> -1) then
  for n := 1 to Num do
  begin
    Coords.X := Coords1.X+(Coords2.X-Coords1.X)*n/(Num+1);
    Coords.Y := Coords1.Y+(Coords2.Y-Coords1.Y)*n/(Num+1);
    Coords.Z := Coords1.Z+(Coords2.Z-Coords1.Z)*n/(Num+1);

    AddPoint(CoordsArr, Coords);
  end;
end;

procedure AddPointBetween3(var CoordsArr : TCoords3DArr;
  Coords1, Coords2, Coords3 : TCoords3D);
var
  Coords, CoordsH : TCoords3D;
begin
  //      1
  //     / \
  //    /   \
  // 2 ------- 3
  //      |
  //   CoordsH

  CoordsH.X := (Coords2.X+Coords3.X) / 2;
  CoordsH.Y := (Coords2.Y+Coords3.Y) / 2;
  CoordsH.Z := (Coords2.Z+Coords3.Z) / 2;

  Coords.X := Coords1.X+(CoordsH.X-Coords1.X)*2/3;
  Coords.Y := Coords1.Y+(CoordsH.Y-Coords1.Y)*2/3;
  Coords.Z := Coords1.Z+(CoordsH.Z-Coords1.Z)*2/3;

  AddPoint(CoordsArr, Coords);
end;

end.