unit ShapeUn;

interface

uses MorphUn, Windows;

type
  TShapes=(shTriangle1, shTriangle2, shCube, shCube2, shCube3, shPyramideTri,
    shOct, shIco, shSphere1, shSphere2, shSphere3, shDodecaedr, shPyramideCut,
    shCubeCut, shHeadAcke, shTor, shSpiral, shFootball);
const
  shCount=18;
  ShapesArr : array[0..shCount-1] of TShapes=
    (shTriangle1, shTriangle2, shCube, shCube2, shCube3, shPyramideTri,
     shOct, shIco, shSphere1, shSphere2, shSphere3, shDodecaedr, shPyramideCut,
     shCubeCut, shHeadAcke, shTor, shSpiral, shFootball);
var
  ShapesSet : set of TShapes = [];
  ShapeInd  : Integer;

procedure InitShape(var CoordsArr : TCoords3DArr);
procedure CalcPos;

implementation

uses DrawUn;

procedure InitTriangle1(var CoordsArr : TCoords3DArr);
var
  n : Integer;
  ang, z : Single;
begin
  // кривая 1 / curve 1
  for n := 0 to (PointsCount div 3)-1 do
  begin
    ang := n/PointsCount* 3 *pi*2; // pi*2 - полная окружность / full round
                                   // n/PointsCount - % круга / of then round
                                   // *_* - сколько точек за раз (div _) /
                                   // how much points at one time
    z := sin(2*ang);

    AddPoint(CoordsArr, XYZ(sin(ang), cos(ang), z));
    AddPoint(CoordsArr, XYZ(cos(ang), z, sin(ang)));
    AddPoint(CoordsArr, XYZ(z, sin(ang), cos(ang)));
  end;
end;

procedure InitTriangle2(var CoordsArr : TCoords3DArr);
var
  n : Integer;
  ang, z : Single;
begin
  // кривая 2 / curve 2
  for n := 0 to (PointsCount div 2)-1 do
  begin
    ang := n/PointsCount* 2 *pi*2; // pi*2 - полная окружность / full round
                                   // n/PointsCount - % круга / of then round
                                   // *_* - сколько точек за раз (div _) /
                                   // how much points at one time
    z := sin(2*ang); // Очень круто ! / Very cool !

    AddPoint(CoordsArr, XYZ(sin(ang)*sqrt(1-z), cos(ang)*sqrt(1+z), z));
    AddPoint(CoordsArr, XYZ(sin(ang+pi/2)*sqrt(1-z), cos(ang+pi/2)*sqrt(1+z), z));
  end;
end;

procedure InitPyramideTri(var CoordsArr : TCoords3DArr);
var
  n : Integer;
begin
  // тетраэдр / tetraedr
  AddPoint(CoordsArr, XYZ(1, 1, 1));    // 0
  AddPoint(CoordsArr, XYZ(-1,  -1, 1)); // 1
  AddPoint(CoordsArr, XYZ(1,  -1, -1)); // 2
  AddPoint(CoordsArr, XYZ(-1, 1, -1));  // 3

  AddPointsBetween(CoordsArr, CoordsArr[0], CoordsArr[1], 39);
  AddPointsBetween(CoordsArr, CoordsArr[1], CoordsArr[2], 39);
  AddPointsBetween(CoordsArr, CoordsArr[2], CoordsArr[3], 39);
  AddPointsBetween(CoordsArr, CoordsArr[0], CoordsArr[2], 39);
  AddPointsBetween(CoordsArr, CoordsArr[0], CoordsArr[3], 39);
  AddPointsBetween(CoordsArr, CoordsArr[1], CoordsArr[3], 39);

  for n := 0 to 1 do DupPoint(CoordsArr);
end;

procedure InitCube(var CoordsArr : TCoords3DArr);
var
  n : Integer;
begin
  // гексаэдр, куб / cube
  AddPoint(CoordsArr, XYZ( 1,  1,  1)); // 0
  AddPoint(CoordsArr, XYZ(-1,  1,  1)); // 1
  AddPoint(CoordsArr, XYZ( 1, -1,  1)); // 2
  AddPoint(CoordsArr, XYZ( 1,  1, -1)); // 3
  AddPoint(CoordsArr, XYZ(-1, -1,  1)); // 4
  AddPoint(CoordsArr, XYZ( 1, -1, -1)); // 5
  AddPoint(CoordsArr, XYZ(-1,  1, -1)); // 6
  AddPoint(CoordsArr, XYZ(-1, -1, -1)); // 7

  AddPointsBetween(CoordsArr, CoordsArr[0], CoordsArr[1], 19);
  AddPointsBetween(CoordsArr, CoordsArr[0], CoordsArr[2], 19);
  AddPointsBetween(CoordsArr, CoordsArr[0], CoordsArr[3], 19);
  AddPointsBetween(CoordsArr, CoordsArr[1], CoordsArr[4], 19);
  AddPointsBetween(CoordsArr, CoordsArr[1], CoordsArr[6], 19);
  AddPointsBetween(CoordsArr, CoordsArr[2], CoordsArr[4], 19);
  AddPointsBetween(CoordsArr, CoordsArr[2], CoordsArr[5], 19);
  AddPointsBetween(CoordsArr, CoordsArr[3], CoordsArr[5], 19);
  AddPointsBetween(CoordsArr, CoordsArr[3], CoordsArr[6], 19);
  AddPointsBetween(CoordsArr, CoordsArr[4], CoordsArr[7], 19);
  AddPointsBetween(CoordsArr, CoordsArr[5], CoordsArr[7], 19);
  AddPointsBetween(CoordsArr, CoordsArr[6], CoordsArr[7], 19);

  for n := 0 to 3 do DupPoint(CoordsArr);
end;

procedure InitCube2(var CoordsArr : TCoords3DArr);
var
  i : Integer;
  ang : Single;
begin
  // Игральный кубик / Play cube
  for i := 0 to 17 do
  begin
    ang := i/18*2*pi;

    AddPoint(CoordsArr, XYZ(1, 0.75*cos(ang), 0.75*sin(ang)));
    AddPoint(CoordsArr, XYZ(-1, 0.75*cos(ang), 0.75*sin(ang)));

    AddPoint(CoordsArr, XYZ(0.75*cos(ang), 1, 0.75*sin(ang)));
    AddPoint(CoordsArr, XYZ(0.75*cos(ang), -1, 0.75*sin(ang)));

    AddPoint(CoordsArr, XYZ(0.75*cos(ang), 0.75*sin(ang), 1));
    AddPoint(CoordsArr, XYZ(0.75*cos(ang), 0.75*sin(ang), -1));
  end;

  for i := 0 to 15 do
  begin
    ang := i/16*2*pi;

    AddPoint(CoordsArr, XYZ(0.875, 0.875*cos(ang), 0.875*sin(ang)));
    AddPoint(CoordsArr, XYZ(-0.875, 0.875*cos(ang), 0.875*sin(ang)));

    AddPoint(CoordsArr, XYZ(0.875*cos(ang), 0.875, 0.875*sin(ang)));
    AddPoint(CoordsArr, XYZ(0.875*cos(ang), -0.875, 0.875*sin(ang)));

    AddPoint(CoordsArr, XYZ(0.875*cos(ang), 0.875*sin(ang), 0.875)); // 7/8
    AddPoint(CoordsArr, XYZ(0.875*cos(ang), 0.875*sin(ang), -0.875));
  end;

  AddPoint(CoordsArr, XYZ(0.725, 0.725, 0.725));
  AddPoint(CoordsArr, XYZ(-0.725, 0.725, 0.725));
  AddPoint(CoordsArr, XYZ(0.725, -0.725, 0.725));
  AddPoint(CoordsArr, XYZ(0.725, 0.725, -0.725));
  AddPoint(CoordsArr, XYZ(-0.725, -0.725, 0.725));
  AddPoint(CoordsArr, XYZ(0.725, -0.725, -0.725));
  AddPoint(CoordsArr, XYZ(-0.725, 0.725, -0.725));
  AddPoint(CoordsArr, XYZ(-0.725, -0.725, -0.725));

  AddPoint(CoordsArr, XYZ(0, 0, 1));

  AddPoint(CoordsArr, XYZ(0.25, 1, 0.25));
  AddPoint(CoordsArr, XYZ(-0.25, 1, -0.25));

  AddPoint(CoordsArr, XYZ(-1, -0.25, 0.25));
  AddPoint(CoordsArr, XYZ(-1, 0, 0));
  AddPoint(CoordsArr, XYZ(-1, 0.25, -0.25));

  AddPoint(CoordsArr, XYZ(0.25, 0.25, -1));
  AddPoint(CoordsArr, XYZ(-0.25, 0.25, -1));
  AddPoint(CoordsArr, XYZ(0.25, -0.25, -1));
  AddPoint(CoordsArr, XYZ(-0.25, -0.25, -1));

  AddPoint(CoordsArr, XYZ(1, 0.25, 0.25));
  AddPoint(CoordsArr, XYZ(1, -0.25, 0.25));
  AddPoint(CoordsArr, XYZ(1, 0.25, -0.25));
  AddPoint(CoordsArr, XYZ(1, -0.25, -0.25));
  AddPoint(CoordsArr, XYZ(1, 0, 0));

  AddPoint(CoordsArr, XYZ(0, -1, 0.4));
  AddPoint(CoordsArr, XYZ(-0.2, -1, 0.2));
  AddPoint(CoordsArr, XYZ(-0.4, -1, 0));
  AddPoint(CoordsArr, XYZ(0.4, -1, 0));
  AddPoint(CoordsArr, XYZ(0.2, -1, -0.2));
  AddPoint(CoordsArr, XYZ(0, -1, -0.4));

  for i := 0 to 6 do DupPoint(CoordsArr);
end;

procedure InitOctaedr(var CoordsArr : TCoords3dArr);
var
  n : Integer;
begin
  // октаэдр / octaedr
  AddPoint(CoordsArr, XYZ(0,  0,  1)); // 2
  AddPoint(CoordsArr, XYZ(1,  0,  0)); // 0
  AddPoint(CoordsArr, XYZ(0,  1,  0)); // 1
  AddPoint(CoordsArr, XYZ(-1, 0,  0)); // 3
  AddPoint(CoordsArr, XYZ(0, -1,  0)); // 4
  AddPoint(CoordsArr, XYZ(0,  0, -1)); // 5

  AddPointsBetween(CoordsArr, CoordsArr[0], CoordsArr[1], 19);
  AddPointsBetween(CoordsArr, CoordsArr[0], CoordsArr[2], 19);
  AddPointsBetween(CoordsArr, CoordsArr[0], CoordsArr[3], 19);
  AddPointsBetween(CoordsArr, CoordsArr[0], CoordsArr[4], 19);
  AddPointsBetween(CoordsArr, CoordsArr[1], CoordsArr[2], 19);
  AddPointsBetween(CoordsArr, CoordsArr[2], CoordsArr[3], 19);

  AddPointsBetween(CoordsArr, CoordsArr[3], CoordsArr[4], 19);
  AddPointsBetween(CoordsArr, CoordsArr[4], CoordsArr[1], 19);
  AddPointsBetween(CoordsArr, CoordsArr[5], CoordsArr[1], 19);
  AddPointsBetween(CoordsArr, CoordsArr[5], CoordsArr[2], 19);
  AddPointsBetween(CoordsArr, CoordsArr[5], CoordsArr[3], 19);
  AddPointsBetween(CoordsArr, CoordsArr[5], CoordsArr[4], 19);

  for n := 0 to 5 do DupPoint(CoordsArr);
end;

procedure InitIcosaedr(var CoordsArr : TCoords3DArr);
var
  n : Integer;
  ang : Single;
begin
  // икосаэдр / icosaedr

  for n := 0 to 4 do //0-9
  begin
    ang := n/5*2*pi; // 5 делений / 5 divisions
    AddPoint(CoordsArr, XYZ(sin(ang), cos(ang), 0.5));
    AddPoint(CoordsArr, XYZ(sin(ang+pi/5), cos(ang+pi/5), -0.5));
  end;

  AddPoint(CoordsArr, XYZ(0, 0, sqrt(5)/2));  // 10
  AddPoint(CoordsArr, XYZ(0, 0, -sqrt(5)/2)); // 11

  for n := 0 to 9 do
  begin
    AddPointsBetween(CoordsArr, CoordsArr[n], CoordsArr[(n+1) mod 10], 7);
    AddPointsBetween(CoordsArr, CoordsArr[n], CoordsArr[(n+2) mod 10], 7);
    AddPointsBetween(CoordsArr, CoordsArr[n], CoordsArr[10+(n mod 2)], 7);
  end;

  for n := 0 to 17 do DupPoint(CoordsArr);
end;

procedure InitDodecaedr(var CoordsArr : TCoords3DArr);
var
  IcoPoints : array[0..11] of TCoords3D;
  n : Integer;
  ang : Single;
begin
  // додекаэдр / dodecaedr
  for n := 0 to 4 do //0-9
  begin
    ang := n/5*2*pi; // 5 делений / 5 divisions
    IcoPoints[2*n]   := XYZ(sin(ang), cos(ang), 0.5);
    IcoPoints[2*n+1] := XYZ(sin(ang+pi/5), cos(ang+pi/5), -0.5);
  end;

  IcoPoints[10] := XYZ(0, 0, sqrt(5)/2);  // 10
  IcoPoints[11] := XYZ(0, 0, -sqrt(5)/2); // 11

  for n := 0 to 9 do
  begin
    AddPointBetween3(CoordsArr, IcoPoints[n],
      IcoPoints[(n+1) mod 10], IcoPoints[(n+2) mod 10]);
  end;
  for n := 0 to 4 do
  begin
    AddPointBetween3(CoordsArr, IcoPoints[10],
      IcoPoints[2*n], IcoPoints[(2*n+2) mod 10]);
    AddPointBetween3(CoordsArr, IcoPoints[11],
      IcoPoints[2*n+1], IcoPoints[(2*n+3) mod 10]);
  end;

  for n := 0 to 9 do
  begin
    AddPointsBetween(CoordsArr, CoordsArr[n], CoordsArr[(n+1) mod 10], 7);
  end;
  for n := 0 to 4 do
  begin
    AddPointsBetween(CoordsArr, CoordsArr[2*n+10],
      CoordsArr[((2*n+2) mod 10)+10], 7);
    AddPointsBetween(CoordsArr, CoordsArr[2*n+11],
      CoordsArr[((2*n+2) mod 10)+11], 7);
  end;
  for n := 0 to 9 do
    AddPointsBetween(CoordsArr, CoordsArr[n], CoordsArr[n+10], 7);

  for n := 0 to 9 do
    DupPoint(CoordsArr);
end;

procedure InitPyramideCut(var CoordsArr : TCoords3DArr);
var
  i : Integer;
begin
  AddPoint(CoordsArr, XYZ(0.33, 0.33, 1));   // 0
  AddPoint(CoordsArr, XYZ(1, 0.33, 0.33));   // 1
  AddPoint(CoordsArr, XYZ(0.33, 1, 0.33));   // 2

  AddPoint(CoordsArr, XYZ(1, -0.33, -0.33)); // 3
  AddPoint(CoordsArr, XYZ(0.33, -1, -0.33)); // 4
  AddPoint(CoordsArr, XYZ(0.33, -0.33, -1)); // 5

  AddPoint(CoordsArr, XYZ(-0.33, -1, 0.33)); // 6
  AddPoint(CoordsArr, XYZ(-1, -0.33, 0.33)); // 7
  AddPoint(CoordsArr, XYZ(-0.33, -0.33, 1)); // 8

  AddPoint(CoordsArr, XYZ(-1, 0.33, -0.33)); // 9
  AddPoint(CoordsArr, XYZ(-0.33, 1, -0.33)); // 10
  AddPoint(CoordsArr, XYZ(-0.33, 0.33, -1)); // 11

  for i := 0 to 3 do
  begin
    AddPointsBetween(CoordsArr, CoordsArr[i*3+0], CoordsArr[i*3+1], 10);
    AddPointsBetween(CoordsArr, CoordsArr[i*3+1], CoordsArr[i*3+2], 10);
    AddPointsBetween(CoordsArr, CoordsArr[i*3+0], CoordsArr[i*3+2], 10);
  end;

  AddPointsBetween(CoordsArr, CoordsArr[0], CoordsArr[8], 18);
  AddPointsBetween(CoordsArr, CoordsArr[1], CoordsArr[3], 18);
  AddPointsBetween(CoordsArr, CoordsArr[2], CoordsArr[10], 18);
  AddPointsBetween(CoordsArr, CoordsArr[4], CoordsArr[6], 18);
  AddPointsBetween(CoordsArr, CoordsArr[7], CoordsArr[9], 18);
  AddPointsBetween(CoordsArr, CoordsArr[5], CoordsArr[11], 18);
end;

procedure InitCubeCut(var CoordsArr : TCoords3DArr);
begin
  AddPoint(CoordsArr, XYZ(1, 0.4, 1));    // 0
  AddPoint(CoordsArr, XYZ(0.4, 1, 1));    // 1
  AddPoint(CoordsArr, XYZ(-0.4, 1, 1));   // 2
  AddPoint(CoordsArr, XYZ(-1, 0.4, 1));   // 3
  AddPoint(CoordsArr, XYZ(-1, -0.4, 1));  // 4
  AddPoint(CoordsArr, XYZ(-0.4, -1, 1));  // 5
  AddPoint(CoordsArr, XYZ(0.4, -1, 1));   // 6
  AddPoint(CoordsArr, XYZ(1, -0.4, 1));   // 7
  AddPoint(CoordsArr, XYZ(1, 1, 0.4));    // 8
  AddPoint(CoordsArr, XYZ(1, 1, -0.4));   // 9
  AddPoint(CoordsArr, XYZ(0.4, 1, -1));   // 10
  AddPoint(CoordsArr, XYZ(-0.4, 1, -1));  // 11
  AddPoint(CoordsArr, XYZ(-1, 1, -0.4));  // 12
  AddPoint(CoordsArr, XYZ(-1, 1, 0.4));   // 13
  AddPoint(CoordsArr, XYZ(1, -1, 0.4));   // 14
  AddPoint(CoordsArr, XYZ(1, -1, -0.4));  // 15
  AddPoint(CoordsArr, XYZ(1, -0.4, -1));  // 16
  AddPoint(CoordsArr, XYZ(1, 0.4, -1));   // 17
  AddPoint(CoordsArr, XYZ(-1, 0.4, -1));  // 18
  AddPoint(CoordsArr, XYZ(-1, -0.4, -1)); // 19
  AddPoint(CoordsArr, XYZ(-0.4, -1, -1)); // 20
  AddPoint(CoordsArr, XYZ(0.4, -1, -1));  // 21
  AddPoint(CoordsArr, XYZ(-1, -1, 0.4));  // 22
  AddPoint(CoordsArr, XYZ(-1, -1, -0.4)); // 23

  AddPointsBetween(CoordsArr, CoordsArr[0],  CoordsArr[1], 6);
  AddPointsBetween(CoordsArr, CoordsArr[1],  CoordsArr[8], 6);
  AddPointsBetween(CoordsArr, CoordsArr[8],  CoordsArr[0], 6);
  AddPointsBetween(CoordsArr, CoordsArr[2],  CoordsArr[3], 6);
  AddPointsBetween(CoordsArr, CoordsArr[3],  CoordsArr[13], 6);
  AddPointsBetween(CoordsArr, CoordsArr[13], CoordsArr[2], 6);
  AddPointsBetween(CoordsArr, CoordsArr[4],  CoordsArr[5], 6);
  AddPointsBetween(CoordsArr, CoordsArr[5],  CoordsArr[22], 6);
  AddPointsBetween(CoordsArr, CoordsArr[22], CoordsArr[4], 6);
  AddPointsBetween(CoordsArr, CoordsArr[6],  CoordsArr[7], 6);
  AddPointsBetween(CoordsArr, CoordsArr[7],  CoordsArr[14], 6);
  AddPointsBetween(CoordsArr, CoordsArr[14], CoordsArr[6], 6);
  AddPointsBetween(CoordsArr, CoordsArr[11], CoordsArr[12], 6);
  AddPointsBetween(CoordsArr, CoordsArr[12], CoordsArr[18], 6);
  AddPointsBetween(CoordsArr, CoordsArr[18], CoordsArr[11], 6);
  AddPointsBetween(CoordsArr, CoordsArr[19], CoordsArr[23], 6);
  AddPointsBetween(CoordsArr, CoordsArr[23], CoordsArr[20], 6);
  AddPointsBetween(CoordsArr, CoordsArr[20], CoordsArr[19], 6);
  AddPointsBetween(CoordsArr, CoordsArr[15], CoordsArr[16], 6);
  AddPointsBetween(CoordsArr, CoordsArr[16], CoordsArr[21], 6);
  AddPointsBetween(CoordsArr, CoordsArr[21], CoordsArr[15], 6);
  AddPointsBetween(CoordsArr, CoordsArr[9],  CoordsArr[17], 6);
  AddPointsBetween(CoordsArr, CoordsArr[17], CoordsArr[10], 6);
  AddPointsBetween(CoordsArr, CoordsArr[10], CoordsArr[9], 6);

  AddPointsBetween(CoordsArr, CoordsArr[1],  CoordsArr[2], 6);
  AddPointsBetween(CoordsArr, CoordsArr[5],  CoordsArr[6], 6);
  AddPointsBetween(CoordsArr, CoordsArr[20], CoordsArr[21], 6);
  AddPointsBetween(CoordsArr, CoordsArr[10], CoordsArr[11], 6);
  AddPointsBetween(CoordsArr, CoordsArr[3],  CoordsArr[4], 6);
  AddPointsBetween(CoordsArr, CoordsArr[7],  CoordsArr[0], 6);
  AddPointsBetween(CoordsArr, CoordsArr[16], CoordsArr[17], 6);
  AddPointsBetween(CoordsArr, CoordsArr[18], CoordsArr[19], 6);
  AddPointsBetween(CoordsArr, CoordsArr[12], CoordsArr[13], 6);
  AddPointsBetween(CoordsArr, CoordsArr[22], CoordsArr[23], 6);
  AddPointsBetween(CoordsArr, CoordsArr[14], CoordsArr[15], 6);
  AddPointsBetween(CoordsArr, CoordsArr[8],  CoordsArr[9], 6);
end;

procedure InitHeadAcke(var CoordsArr : TCoords3DArr);
var
  i : Integer;
begin
  AddPoint(CoordsArr, XYZ(1, 0.4, 0.2));    // 0
  AddPoint(CoordsArr, XYZ(-1, 0.4, 0.2));   // 1
  AddPoint(CoordsArr, XYZ(-1, -0.4, 0.2));  // 2
  AddPoint(CoordsArr, XYZ(1, -0.4, 0.2));   // 3
  AddPoint(CoordsArr, XYZ(1, 0.4, -0.2));   // 4
  AddPoint(CoordsArr, XYZ(-1, 0.4, -0.2));  // 5
  AddPoint(CoordsArr, XYZ(-1, -0.4, -0.2)); // 6
  AddPoint(CoordsArr, XYZ(1, -0.4, -0.2));  // 7
  AddPoint(CoordsArr, XYZ(0.4, 0.2, 1));     // 8
  AddPoint(CoordsArr, XYZ(0.4, 0.2, -1));    // 9
  AddPoint(CoordsArr, XYZ(-0.4, 0.2, -1));   // 10
  AddPoint(CoordsArr, XYZ(-0.4, 0.2, 1));    // 11
  AddPoint(CoordsArr, XYZ(0.4, -0.2, 1));    // 12
  AddPoint(CoordsArr, XYZ(0.4, -0.2, -1));   // 13
  AddPoint(CoordsArr, XYZ(-0.4, -0.2, -1));  // 14
  AddPoint(CoordsArr, XYZ(-0.4, -0.2, 1));   // 15
  AddPoint(CoordsArr, XYZ(0.2, 1, 0.4));    // 16
  AddPoint(CoordsArr, XYZ(0.2, -1, 0.4));   // 17
  AddPoint(CoordsArr, XYZ(0.2, -1, -0.4));  // 18
  AddPoint(CoordsArr, XYZ(0.2, 1, -0.4));   // 19
  AddPoint(CoordsArr, XYZ(-0.2, 1, 0.4));   // 20
  AddPoint(CoordsArr, XYZ(-0.2, -1, 0.4));  // 21
  AddPoint(CoordsArr, XYZ(-0.2, -1, -0.4)); // 22
  AddPoint(CoordsArr, XYZ(-0.2, 1, -0.4));  // 23

  for i := 0 to 5 do
  begin
    AddPointsBetween(CoordsArr, CoordsArr[4*i+0], CoordsArr[4*i+1], 10);
    AddPointsBetween(CoordsArr, CoordsArr[4*i+1], CoordsArr[4*i+2], 5);
    AddPointsBetween(CoordsArr, CoordsArr[4*i+2], CoordsArr[4*i+3], 10);
    AddPointsBetween(CoordsArr, CoordsArr[4*i+3], CoordsArr[4*i+0], 5);
  end;

  for i := 0 to 2 do
  begin
    AddPointsBetween(CoordsArr, CoordsArr[8*i+0], CoordsArr[8*i+4], 3);
    AddPointsBetween(CoordsArr, CoordsArr[8*i+1], CoordsArr[8*i+5], 3);
    AddPointsBetween(CoordsArr, CoordsArr[8*i+2], CoordsArr[8*i+6], 3);
    AddPointsBetween(CoordsArr, CoordsArr[8*i+3], CoordsArr[8*i+7], 3);
  end;
end;

procedure InitSphere1(var CoordsArr : TCoords3DArr);
var
  nokr, nang : Integer;
  ango, anga, z : Single;
begin
  for nang := -9 to 10 do
  begin
    anga := (nang-0.5)/20 *pi;
    z := sin(anga);
    for nokr := 0 to 11 do
    begin
      ango := nokr/12*pi*2;
      AddPoint(CoordsArr, XYZ(sin(ango)*sqrt(1-z*z), cos(ango)*sqrt(1-z*z), z));
    end;
  end;
end;

procedure InitSphere2(var CoordsArr : TCoords3DArr);
var
  nokr, nang : Integer;
  ango, anga, z : Single;
begin
  for nang := -5 to 6 do
  begin
    anga := (nang-0.5)/12 *pi;
    z := sin(anga);
    for nokr := 0 to 19 do
    begin
      ango := nokr/20*pi*2;
      AddPoint(CoordsArr, XYZ(sin(ango)*sqrt(1-z*z), cos(ango)*sqrt(1-z*z), z));
    end;
  end;
end;

procedure InitSphere3(var CoordsArr : TCoords3DArr);
var
  nokr, nsl : Integer;
  anga, ango, x, y, z : Single;
begin
  for nsl := -4 to 5 do
  begin
    anga := (nsl-0.5)/10*pi;
    z := sin(anga);
    for nokr := 0 to 7 do
    begin
      ango := nokr/8*2*pi;
      x := sin(ango)*sqrt(1-z*z);
      y := cos(ango)*sqrt(1-z*z);

      AddPoint(CoordsArr, XYZ(x, y, z));
      AddPoint(CoordsArr, XYZ(x, z, y));
      AddPoint(CoordsArr, XYZ(z, x, y));
    end;
  end;
end;

procedure InitTor(var CoordsArr : TCoords3DArr);
var
  n, k : Integer;
  r, xa, ya, za, ang : Single;
begin
  // тор / torus
  for n := 0 to (PointsCount div 12)-1 do
  begin
    ang := n/PointsCount * 12 * 2 *pi;

    for k := 0 to 11 do
    begin
      r  := 1+0.33*cos(k/12*2*pi);
      za := 0.33*sin(k/12*2*pi);

      xa := r*cos(ang);
      ya := r*sin(ang);

      AddPoint(CoordsArr, XYZ(xa, ya, za));
    end;
  end;
end;

procedure InitSpiral(var CoordsArr : TCoords3DArr);
var
  n : Integer;
  angm, ang, r, xa, ya, za : Single;
begin
  // спираль / spiral
  for n := 0 to (PointsCount-1) do
  begin
    angm := n/PointsCount * 2*pi;
    ang := angm*16;
    za := 0.33*sin(ang);

    r := 1+0.33*cos(ang);
    xa := r*cos(angm);
    ya := r*sin(angm);

    AddPoint(CoordsArr, XYZ(xa, ya, za));
  end;
end;

procedure InitFootball(var CoordsArr : TCoords3DArr);
var
  n : Integer;
  arr : array[0..9] of TCoords3D;
const
  Ang = 2.59;
  h = 1;
  r = 0.431;
  sin_pi_5 = 0.588;
  cos_pi_5 = 0.809;
  r0 = 0.5*r/sin_pi_5;
  cos_Ang=-0.852;
  r1_1 = r0-r*cos_Ang;
  r1_2 = r0-2*r*cos_Ang;
  c = 2*cos_pi_5/(4*cos_pi_5+1);
  ap = 2;
begin
  for n := 0 to 4 do // 0-4
  begin
    AddPoint(CoordsArr, XYZ(r0*cos(n/5*2*pi), r0*sin(n/5*2*pi), h));
  end;

  for n := 0 to 4 do // 5-9
    AddPoint(CoordsArr, XYZ(r1_1*cos(n/5*2*pi), r1_1*sin(n/5*2*pi), h-r*sin(Ang) ));

  for n := 0 to 4 do
    arr[n] := XYZ(r1_2*cos(n/5*2*pi), r1_2*sin(n/5*2*pi), h-2*r*sin(Ang));

  for n := 0 to 4 do // 10-19
    AddPointsBetween(CoordsArr, arr[n], arr[(n+1) mod 5], 2);

   // 20-29
  for n := 0 to 4 do
  begin
    if n>0 then
      Arr[0] := XYZ(
    CoordsArr[n+5].X+(CoordsArr[2*n+9].X-CoordsArr[n+5].X)*(1+2*cos(pi/5)),
    CoordsArr[n+5].Y+(CoordsArr[2*n+9].Y-CoordsArr[n+5].Y)*(1+2*cos(pi/5)),
    CoordsArr[n+5].Z+(CoordsArr[2*n+9].Z-CoordsArr[n+5].Z)*(1+2*cos(pi/5))
    ) else
      arr[0] := XYZ(
    CoordsArr[5].X+(CoordsArr[19].X-CoordsArr[5].X)*(1+2*cos(pi/5)),
    CoordsArr[5].Y+(CoordsArr[19].Y-CoordsArr[5].Y)*(1+2*cos(pi/5)),
    CoordsArr[5].Z+(CoordsArr[19].Z-CoordsArr[5].Z)*(1+2*cos(pi/5)));

    arr[1] := XYZ(
    CoordsArr[n+5].X+(CoordsArr[2*n+10].X-CoordsArr[n+5].X)*(1+2*cos(pi/5)),
    CoordsArr[n+5].Y+(CoordsArr[2*n+10].Y-CoordsArr[n+5].Y)*(1+2*cos(pi/5)),
    CoordsArr[n+5].Z+(CoordsArr[2*n+10].Z-CoordsArr[n+5].Z)*(1+2*cos(pi/5)));

    AddPoint(CoordsArr, XYZ(
      arr[0].X+(arr[1].X-arr[0].X)*c,
      arr[0].Y+(arr[1].Y-arr[0].Y)*c,
      arr[0].Z+(arr[1].Z-arr[0].Z)*c));
    AddPoint(CoordsArr, XYZ(
      arr[1].X-(arr[1].X-arr[0].X)*c,
      arr[1].Y-(arr[1].Y-arr[0].Y)*c,
      arr[1].Z-(arr[1].Z-arr[0].Z)*c));
  end;

  for n := 0 to 9 do
  arr[n] := XYZ(
    CoordsArr[n+10].X+(CoordsArr[((n+1) mod 10)+20].X-CoordsArr[n+10].X)*2,
    CoordsArr[n+10].Y+(CoordsArr[((n+1) mod 10)+20].Y-CoordsArr[n+10].Y)*2,
    CoordsArr[n+10].Z+(CoordsArr[((n+1) mod 10)+20].Z-CoordsArr[n+10].Z)*2);
  for n := 0 to 4 do // 30-39
    AddPointsBetween(CoordsArr, arr[2*n], arr[2*n+1], 2);

  for n := 0 to 9 do
  begin
    arr[n] := XYZ(
      CoordsArr[n+20].X+(CoordsArr[((n+9) mod 10)+30].X-CoordsArr[n+20].X)*2,
      CoordsArr[n+20].Y+(CoordsArr[((n+9) mod 10)+30].Y-CoordsArr[n+20].Y)*2,
      CoordsArr[n+20].Z+(CoordsArr[((n+9) mod 10)+30].Z-CoordsArr[n+20].Z)*2);
  end;
  for n := 0 to 4 do // 40-49
    AddPointsBetween(CoordsArr, arr[2*n], arr[2*n+1], 2);

  for n := 0 to 4 do
  begin
    arr[0] := XYZ(
      CoordsArr[2*n+30].X+(CoordsArr[2*n+41].X-CoordsArr[2*n+30].X)*(1+2*sin(pi/10)),
      CoordsArr[2*n+30].Y+(CoordsArr[2*n+41].Y-CoordsArr[2*n+30].Y)*(1+2*sin(pi/10)),
      CoordsArr[2*n+30].Z+(CoordsArr[2*n+41].Z-CoordsArr[2*n+30].Z)*(1+2*sin(pi/10)));
    if n<4 then
    arr[1] := XYZ(
      CoordsArr[2*n+31].X+(CoordsArr[2*n+42].X-CoordsArr[2*n+31].X)*(1+2*sin(pi/10)),
      CoordsArr[2*n+31].Y+(CoordsArr[2*n+42].Y-CoordsArr[2*n+31].Y)*(1+2*sin(pi/10)),
      CoordsArr[2*n+31].Z+(CoordsArr[2*n+42].Z-CoordsArr[2*n+31].Z)*(1+2*sin(pi/10))) else
    arr[1] := XYZ(
      CoordsArr[39].X+(CoordsArr[40].X-CoordsArr[39].X)*(1+2*sin(pi/10)),
      CoordsArr[39].Y+(CoordsArr[40].Y-CoordsArr[39].Y)*(1+2*sin(pi/10)),
      CoordsArr[39].Z+(CoordsArr[40].Z-CoordsArr[39].Z)*(1+2*sin(pi/10)));
    AddPointsBetween(CoordsArr, arr[0], arr[1], 1); // 50-54
  end;

  for n := 0 to 9 do
  begin
    if n>0 then arr[n] := XYZ(
      CoordsArr[n+40].X+(CoordsArr[((n+1) div 2)+49].X-CoordsArr[n+40].X)*2,
      CoordsArr[n+40].Y+(CoordsArr[((n+1) div 2)+49].Y-CoordsArr[n+40].Y)*2,
      CoordsArr[n+40].Z+(CoordsArr[((n+1) div 2)+49].Z-CoordsArr[n+40].Z)*2
    ) else
    arr[n] := XYZ(
      CoordsArr[40].X+(CoordsArr[54].X-CoordsArr[40].X)*2,
      CoordsArr[40].Y+(CoordsArr[54].Y-CoordsArr[40].Y)*2,
      CoordsArr[40].Z+(CoordsArr[54].Z-CoordsArr[40].Z)*2);
  end;

  for n := 0 to 4 do // 55-59
    AddPoint(CoordsArr, XYZ(
      arr[2*n+0].X+(arr[2*n+1].X-arr[2*n+0].X)*0.333,
      arr[2*n+0].Y+(arr[2*n+1].Y-arr[2*n+0].Y)*0.333,
      arr[2*n+0].Z+(arr[2*n+1].Z-arr[2*n+0].Z)*0.333));

  for n := 0 to 4 do
  begin
    AddPointsBetween(CoordsArr, CoordsArr[n], CoordsArr[(n+1) mod 5], ap);

    AddPointsBetween(CoordsArr, CoordsArr[n], CoordsArr[n+5], ap);
    AddPointsBetween(CoordsArr, CoordsArr[n+5], CoordsArr[2*n+10], ap);

    if n>0 then
      AddPointsBetween(CoordsArr, CoordsArr[n+5], CoordsArr[2*n+9], ap) else
      AddPointsBetween(CoordsArr, CoordsArr[5], CoordsArr[19], ap);
    AddPointsBetween(CoordsArr, CoordsArr[2*n+10], CoordsArr[2*n+11], ap);

    AddPointsBetween(CoordsArr, CoordsArr[n+10], CoordsArr[n+21], ap);
    AddPointsBetween(CoordsArr, CoordsArr[n+15], CoordsArr[((n+6) mod 10)+20], ap);

    AddPointsBetween(CoordsArr, CoordsArr[2*n+20], CoordsArr[2*n+21], ap);

    AddPointsBetween(CoordsArr, CoordsArr[n+20], CoordsArr[((n+9) mod 10)+30], ap);
    AddPointsBetween(CoordsArr, CoordsArr[n+25], CoordsArr[n+34], ap);

    AddPointsBetween(CoordsArr, CoordsArr[2*n+30], CoordsArr[2*n+31], ap);

    AddPointsBetween(CoordsArr, CoordsArr[n+30], CoordsArr[n+41], ap);
    AddPointsBetween(CoordsArr, CoordsArr[n+35], CoordsArr[((n+6) mod 10)+40], ap);

    AddPointsBetween(CoordsArr, CoordsArr[2*n+40], CoordsArr[2*n+41], ap);

    AddPointsBetween(CoordsArr, CoordsArr[n+40], CoordsArr[ (((n+9) mod 10) div 2)+50], ap);
    AddPointsBetween(CoordsArr, CoordsArr[n+45], CoordsArr[(n div 2)+52], ap);

    AddPointsBetween(CoordsArr, CoordsArr[n+50], CoordsArr[((n+1) mod 5)+55], ap);

    AddPointsBetween(CoordsArr, CoordsArr[n+55], CoordsArr[((n+1) mod 5)+55], ap);
  end;
end;

procedure InitCube3(var CoordsArr : TCoords3DArr);
const
  s3=0.577;
var
  n : Integer;
begin
  AddPoint(CoordsArr, XYZ( s3,  s3,  s3)); // 0
  AddPoint(CoordsArr, XYZ(-s3,  s3,  s3)); // 1
  AddPoint(CoordsArr, XYZ( s3, -s3,  s3)); // 2
  AddPoint(CoordsArr, XYZ(-s3, -s3,  s3)); // 3
  AddPoint(CoordsArr, XYZ( s3,  s3, -s3)); // 4
  AddPoint(CoordsArr, XYZ(-s3,  s3, -s3)); // 5
  AddPoint(CoordsArr, XYZ( s3, -s3, -s3)); // 6
  AddPoint(CoordsArr, XYZ(-s3, -s3, -s3)); // 7

  AddPoint(CoordsArr, XYZ(0, 0, 1));  // 8
  AddPoint(CoordsArr, XYZ(0, 0, -1)); // 9
  AddPoint(CoordsArr, XYZ(0, 1, 0));  // 10
  AddPoint(CoordsArr, XYZ(0, -1, 0)); // 11
  AddPoint(CoordsArr, XYZ(1, 0, 0));  // 12
  AddPoint(CoordsArr, XYZ(-1, 0, 0)); // 13

  AddPointsBetween(CoordsArr, CoordsArr[0], CoordsArr[1], 6);
  AddPointsBetween(CoordsArr, CoordsArr[1], CoordsArr[3], 6);
  AddPointsBetween(CoordsArr, CoordsArr[3], CoordsArr[2], 6);
  AddPointsBetween(CoordsArr, CoordsArr[2], CoordsArr[0], 6);
  AddPointsBetween(CoordsArr, CoordsArr[4], CoordsArr[5], 6);
  AddPointsBetween(CoordsArr, CoordsArr[5], CoordsArr[7], 6);
  AddPointsBetween(CoordsArr, CoordsArr[7], CoordsArr[6], 6);
  AddPointsBetween(CoordsArr, CoordsArr[6], CoordsArr[4], 6);
  AddPointsBetween(CoordsArr, CoordsArr[0], CoordsArr[4], 6);
  AddPointsBetween(CoordsArr, CoordsArr[1], CoordsArr[5], 6);
  AddPointsBetween(CoordsArr, CoordsArr[2], CoordsArr[6], 6);
  AddPointsBetween(CoordsArr, CoordsArr[3], CoordsArr[7], 6);

  for n := 0 to 3 do
  begin
    AddPointsBetween(CoordsArr, CoordsArr[n], CoordsArr[8], 6);
    AddPointsBetween(CoordsArr, CoordsArr[2*n+1], CoordsArr[13], 6);
    AddPointsBetween(CoordsArr, CoordsArr[2*n], CoordsArr[12], 6);

    AddPointsBetween(CoordsArr, CoordsArr[n+4], CoordsArr[9], 6);
    AddPointsBetween(CoordsArr, CoordsArr[(n+4) mod 6], CoordsArr[10], 6);
    AddPointsBetween(CoordsArr, CoordsArr[2+((n+4) mod 6)], CoordsArr[11], 6);
  end;

  for n := 0 to 9 do DupPoint(CoordsArr);
end;

procedure UnSort(var CoordsArr : TCoords3DArr);
var
  Temp : TCoords3D;
  i, k, l : Integer;
begin
  for i := 0 to 1023 do
  begin
    k := Random(PointsCount);
    l := Random(PointsCount);

    Temp := CoordsArr[k];
    CoordsArr[k] := CoordsArr[l];
    CoordsArr[l] := Temp;
  end;
end;

procedure InitShape(var CoordsArr : TCoords3dArr);
var
  n, OldShInd : Integer;
  Ok : Boolean;
begin
  FillChar(CoordsArr, SizeOf(TCoords3DArr), 0);

  Ok := False;
  PIndex := 0;

  OldShInd := ShapeInd;
  for n := 0 to shCount-1 do
    if (not (ShapesArr[n] in ShapesSet)) then Ok := True;

  if (not Ok) then ShapesSet := [];
  repeat
    ShapeInd := Trunc(Random(100)) mod shCount;
  until not (ShapesArr[ShapeInd] in ShapesSet) and (ShapeInd<>OldShInd);
  ShapesSet := ShapesSet+[ShapesArr[ShapeInd]];

  case ShapesArr[ShapeInd] of
    shTriangle1   : InitTriangle1(CoordsArr);
    shTriangle2   : InitTriangle2(CoordsArr);
    shCube        : InitCube(CoordsArr);
    shCube2       : InitCube2(CoordsArr);
    shCube3       : InitCube3(CoordsArr);
    shPyramideTri : InitPyramideTri(CoordsArr);
    shOct         : InitOctaedr(CoordsArr);
    shIco         : InitIcosaedr(CoordsArr);
    shSphere1     : InitSphere1(CoordsArr);
    shSphere2     : InitSphere2(CoordsArr);
    shSphere3     : InitSphere3(CoordsArr);
    shDodecaedr   : InitDodecaedr(CoordsArr);
    shPyramideCut : InitPyramideCut(CoordsArr);
    shCubeCut     : InitCubeCut(CoordsArr);
    shHeadAcke    : InitHeadAcke(CoordsArr);
    shTor         : InitTor(CoordsArr);
    shSpiral      : InitSpiral(CoordsArr);
    else InitFootball(CoordsArr);
  end;

  if UnSortPoints then UnSort(CoordsArr); // перемешать точки / mix points
end;

procedure CalcPos;
var
  n : Integer;
begin
  for n := 0 to PointsCount-1 do
  begin
    Points[n].X := PCoords1[n].X+(PCoords2[n].X-PCoords1[n].X)*Percent/100;
    Points[n].Y := PCoords1[n].Y+(PCoords2[n].Y-PCoords1[n].Y)*Percent/100;
    Points[n].Z := PCoords1[n].Z+(PCoords2[n].Z-PCoords1[n].Z)*Percent/100;
  end;
end;

end.
