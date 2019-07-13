unit DrawUn;

interface

uses Windows, MorphUn;

var
  // Relative offset of the beginning of the coordinates center
  SCX : Single=0;
  SCY : Single=0;
  SCZ : Single=0;

  // Absolute 2D-coordinates of coordinates center
  ScrX : Integer=400;
  ScrY : Integer=300;

  // Multiply coefficient for counting absolute coordinates
  CoefX : Single;
  CoefY : Single;

  RAnim : Single=0;
  GAnim : Single=0;
  BAnim : Single=0;
  RTimer : Integer=0;
  GTimer : Integer=0;
  BTimer : Integer=0;

  // Horizontal and vertical projections of the vector of moving 3D-center
  VectX : Single= 0.00050;//0.00075;//0.00093;
  VectY : Single= 0.00060;//0.00090;//0.00111;
  VectZ : Single= 0.00100;//0.00150;//0.00180;

  // Rotation (pi) of the figure per 1 second
  VectAX : Single=0.17;//0.24;//0.35;
  VectAY : Single=0.14;//0.28;//0.25;
  VectAZ : Single=0.00; //

var
  // Rotate angles around the beginning of the coordinates
  xa, ya, za : Single;

  LastTickCount : Single;

  PCoords1, PCoords2, Points : TCoords3DArr;

  LastLeft : Integer=0;
  LastTop : Integer=0;
  LastRight : Integer=0;
  LastBottom : Integer=0;

const
  // Z-coordinate of camera - (X=0, Y=0, Z=CamZ)
  CamZ = 10;
  // 3^0.5 Coordinate for the calculation of
  // the color of the point
  ColorZ0 = 1.732;
  // Fog coefficient
  FogCoef = 64;

procedure DrawScreen;

implementation

uses ShapeUn;

function GetRect(Left, Top, Width, Height : Integer) : TRect;
begin
  Result.Left   := Left;
  Result.Top    := Top;
  Result.Right  := Left+Width;
  Result.Bottom := Top+Height;
end;

procedure DrawPoint(Coords2D : TCoords2D; ColorPal : byte; Color, Color2 : TColor);
  procedure SetPixel(x, y : Integer; C : byte);
  var
    px : PByte;
  begin
    px := Pointer(LongInt(bitptr)+WndWidth*y+x);
    if C>px^ then px^ := C;
  end;
var
  Rect : TRect;
  i, j : Integer;
begin
  if (Coords2D.X<2) or (Coords2D.X>WndRect.Right-3) or
    (Coords2D.Y<2) or (Coords2D.Y>WndRect.Bottom-4) then Exit;

  if (not Preview) then
  begin
    if (not Trace) then
    begin
      SetBkColor(CDC, Color);
      Rect := GetRect(Coords2d.X-1, Coords2d.Y-1, 3, 3);
      ExtTextOut(CDC, 0, 0, ETO_OPAQUE, @Rect, nil, 0, nil);

      if (not PrimitivePoints) then
      begin
        SetBkColor(CDC, Color2);
        Rect := GetRect(Coords2d.X-1, Coords2d.Y, 3, 1);
        ExtTextOut(CDC, 0, 0, ETO_OPAQUE, @Rect, nil, 0, nil);

        Rect := GetRect(Coords2d.X, Coords2d.Y-1, 1, 3);
        ExtTextOut(CDC, 0, 0, ETO_OPAQUE, @Rect, nil, 0, nil);
      end;
    end else
    begin
      for i := -1 to 1 do
      for j := -1 to 1 do
        SetPixel(Coords2d.x+i, Coords2d.y+j, ColorPal);
    end;

    Rect := GetRect(Coords2d.X-1, Coords2d.Y-1, 4, 4);

    if (not Trace) then
    begin
      if Rect.Left<LastLeft then LastLeft := Rect.Left;
      if Rect.Right>LastRight then LastRight := Rect.Right;
      if Rect.Top<LastTop then LastTop := Rect.Top;
      if Rect.Bottom>LastBottom then LastBottom := Rect.Bottom;
    end;
  end else
  begin
    if (not Trace) then
    begin
      SetBkColor(CDC, Color);
      Rect := GetRect(Coords2d.X, Coords2d.Y, 1, 1);
      ExtTextOut(CDC, 0, 0, ETO_OPAQUE, @Rect, nil, 0, nil);
    end else
    SetPixel(Coords2d.x, Coords2d.y, ColorPal);
  end;
end;

// Screen Savers' engine
function GetCoords2D(Coords3D : TCoords3D) : TCoords2D;
var
  ZNorm : Single;
begin
  ZNorm := 1-(Coords3D.Z+SCZ)/CamZ;
  if ZNorm <> 0 then
  begin
    Result.X := Round((Coords3D.X+SCX)/ZNorm*CoefX)+ScrX;
    Result.Y := Round((Coords3D.Y+SCY)/ZNorm*CoefY)+ScrY;
  end;
end;

function Rotate3D(Coords3D : TCoords3D) : TCoords3D;
var
  sina, cosa : Single;
begin
  if (xa<>0) then
  begin
    sina := sin(xa);
    cosa := cos(xa);
    Result.X := Coords3D.X;
    Result.Y := Coords3D.Y*cosa-Coords3D.Z*sina;
    Result.Z := Coords3D.Y*sina+Coords3D.Z*cosa;

    Coords3D.X := Result.X;
    Coords3D.Y := Result.Y;
    Coords3D.Z := Result.Z;
  end;
  if (ya<>0) then
  begin
    sina := sin(ya);
    cosa := cos(ya);
    Result.X := Coords3D.X*cosa+Coords3D.Z*sina;
    Result.Y := Coords3D.Y;
    Result.Z := -Coords3D.X*sina+Coords3D.Z*cosa;

    Coords3D.X := Result.X;
    Coords3D.Y := Result.Y;
    Coords3D.Z := Result.Z;
  end;
  if (za<>0) then
  begin
    sina := sin(za);
    cosa := cos(za);
    Result.X := Coords3D.X*cosa-Coords3D.Y*sina;
    Result.Y := Coords3D.X*sina+Coords3D.Y*cosa;
    Result.Z := Coords3D.Z;

    Coords3D.X := Result.X;
    Coords3D.Y := Result.Y;
    Coords3D.Z := Result.Z;
  end;

  Result.X := Coords3D.X;
  Result.Y := Coords3D.Y;
  Result.Z := Coords3D.Z;
end;

function GetGr(Coords3D : TCoords3D) : byte;
var
  Len : Single;
  Gr : Integer;
begin
  Len := ColorZ0-Coords3D.Z;
  Gr := Trunc(255-Len*FogCoef);

  if (Gr<0) then Gr := 0;
  if (Gr>255) then Gr := 255;

  Result := Gr;
  // Translation RGB to the hue of grey
end;

procedure DrawScreen; // procedure of screen drawing
var
  n : Integer;
  Point : TCoords3D;
  TimeDelta : Single;
  Gr, Gr2 : Integer;
  Coeff : Single;
  palentryarr : array[0..255] of RGBQUAD;
const
  MaxTimeDelta = 40;
begin
  TimeDelta := GetTickCount-LastTickCount;
  if TimeDelta>MaxTimeDelta then TimeDelta := MaxTimeDelta;

  LastTickCount := GetTickCount;

  if (not HuesOfGray) then
  begin
    Inc(RTimer);
    Inc(GTimer);
    Inc(BTimer);
    if RTimer>2*540 then Dec(RTimer, 2*540);
    if GTimer>2*630 then Dec(GTimer, 2*630);
    if BTimer>2*720 then Dec(BTimer, 2*720);
    RAnim := 255*(cos( RTimer/540*pi )+1)/2;
    GAnim := 255*(sin( GTimer/630*pi )+1)/2;
    BAnim := 255*(sin( BTimer/720*pi )+1)/2;
    if (RAnim+GAnim+BAnim<>0) then
      Coeff := 500/(RAnim+GAnim+BAnim) else Coeff := 1;
    RAnim := RAnim*Coeff;
    GAnim := GAnim*Coeff;
    BAnim := BAnim*Coeff;
    if RAnim>255 then RAnim := 255;
    if GAnim>255 then GAnim := 255;
    if BAnim>255 then BAnim := 255;
  end;

  if (Wait>0) then Wait := Wait-TimeDelta else
  begin
    if (DoUp) then
    begin
      Percent := (Percent + (TimeDelta/15));
      if Percent >= 100 then
      begin
        Percent := 100;

        DoUp := False;
        Wait := WaitPer;
        InitShape(PCoords1);
      end;
    end else
    begin
      Percent := (Percent - (TimeDelta/15));
      if Percent <= 0 then
      begin
        Percent := 0;

        DoUp := True;
        Wait := WaitPer;
        InitShape(PCoords2);
      end;
    end;
    CalcPos;
  end;

  if ((Trace) and (not HuesOfGray)) then
  begin
    for n := 0 to 255 do
    begin
      palentryarr[n].rgbRed := Trunc(RAnim/255*n);
      palentryarr[n].rgbGreen := Trunc(GAnim/255*n);
      palentryarr[n].rgbBlue := Trunc(BAnim/255*n);
    end;
    SetDIBColorTable(CDC, 0, 256, palentryarr);
  end;

  xa := xa+TimeDelta*pi*VectAX/1000;
  ya := ya+TimeDelta*pi*VectAY/1000;
  za := za-TimeDelta*pi*VectAZ/1000;

  SCX := SCX+VectX*TimeDelta;
  if (SCX>3.5-SCZ/2.5) or ((SCX>2.75) and (not Move3D)) then
  begin
    VectX := -abs(VectX);
    if (not Trace) then VectAY := -abs(Random/7+0.30) else
      VectAY := -abs(Random/10+0.12);
  end;
  if (SCX<-3.5+SCZ/2.5) or ((SCX<-2.75) and (not Move3D)) then
  begin
    VectX := abs(VectX);
    if (not Trace) then VectAY := abs(Random/7+0.30) else
      VectAY := abs(Random/10+0.12);
  end;

  SCY := SCY+VectY*TimeDelta;
  if (SCY>3-SCZ/3) or ((SCY>1.8) and (not Move3D)) then
  begin
    VectY := -abs(VectY);
    if (not Trace) then VectAX := -abs(Random/7+0.30) else
      VectAX := -abs(Random/10+0.12);
  end;
  if (SCY<-3+SCZ/3) or ((SCY<-1.8) and (not Move3D)) then
  begin
    VectY := abs(VectY);
    if (not Trace) then VectAX := abs(Random/7+0.30) else
      VectAX := abs(Random/10+0.12);
  end;

  if (Move3D) then
  begin
    SCZ := SCZ+VectZ*TimeDelta;
    if (SCZ>4) then
    begin
      VectZ := -abs(VectZ);
      VectAX := -abs(Random/3+0.25);
      VectAY := -abs(Random/3+0.25);
    end;
    if (SCZ<-10) then
    begin
      VectZ := abs(VectZ);
      VectAX := abs(Random/3+0.25);
      VectAY := abs(Random/3+0.25);
    end;
  end;

  for n := 0 to PointsCount-1 do
  begin
    Point := Rotate3D(Points[n]);
    Gr := GetGr(Point);
    if (Trace) then DrawPoint(GetCoords2D(Point), Gr, 0, 0) else
    begin
      if (not PrimitivePoints) then Gr2 := Trunc(Gr/1.5) else Gr2 := Gr;
      if (not HuesOfGray) then
        DrawPoint(GetCoords2D(Point), 0,
          RGB(Trunc(RAnim*Gr2/255), Trunc(GAnim*Gr2/255), Trunc(BAnim*Gr2/255)),
          RGB(Trunc(RAnim*Gr/255), Trunc(GAnim*Gr/255), Trunc(BAnim*Gr/255))) else
        DrawPoint(GetCoords2D(Point), 0, RGB(Gr2, Gr2, Gr2), RGB(Gr, Gr, Gr));
    end;
  end;
end;

end.
