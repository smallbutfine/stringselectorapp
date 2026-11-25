unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Grids, Math, IniFiles, Spin, LclIntf;

type
  TSetStringItem = record
    Gauge: Double;
    UnitWeight: Double;
  end;

  TStringPack = record
    ProductName: string;
    StringCount: Integer;
    Strings: array[1..9] of TSetStringItem;
  end;

  TStringConfig = record
    NoteName: string;
    SemitonesFromA4: Integer;
    TargetTension: Double;
  end;

  TTuningPreset = record
    Name: string;
    StringCount: Integer;
    Notes: array[1..9] of string;
  end;

  TForm1 = class(TForm)
    BtnCalculate: TButton;
    ComboInstrument: TComboBox;
    ComboTuning: TComboBox;
    EditScaleTreble: TEdit;
    EditScaleBass: TEdit;
    GridResults: TStringGrid;
    SpinStrings: TSpinEdit;
    LabelRecommendation: TLabel;
    CheckISO: TCheckBox;
    BtnExport: TButton;
    BtnSaveTuning: TButton;
    BtnPrintPDF: TButton;
    SpinTranspose: TSpinEdit;
    SpinPitch: TSpinEdit;
    LabelTranspose: TLabel;
    LabelPitch: TLabel;
    LabelISO: TLabel;
    LabelScaleTreble: TLabel;
    LabelScaleBass: TLabel;
    LabelBaseGuitar: TLabel;
    EditBaseGuitar: TEdit;
    LabelBaseBass: TLabel;
    EditBaseBass: TEdit;
    LabelProNotice: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure BtnCalculateClick(Sender: TObject);
    procedure SpinStringsChange(Sender: TObject);
    procedure GridResultsDrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
    procedure BtnExportClick(Sender: TObject);
    procedure BtnSaveTuningClick(Sender: TObject);
    procedure BtnPrintPDFClick(Sender: TObject);
    procedure CheckISOChange(Sender: TObject);
  private
    FSuppressDialog: Boolean;
    StringDatabase: array of TStringPack;
    TuningPresets: array of TTuningPreset;
    procedure InitializeDatabase;
    procedure LoadTuningPresets;
    function CalculateFrequency(SemitonesFromA4: Integer; BaseA4: Double): Double;
    function CalculateTension(UnitWeight, ScaleLength, Frequency: Double): Double;
    procedure SetupGridHeaders;
    function NoteNameToSemitones(Note: string): Integer;
    procedure FillCustomDefaults;
    function TransposeNoteName(Note: string; Steps: Integer): string;
  public
  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

procedure TForm1.InitializeDatabase;
var
  Ini: TMemIniFile;
  IniPath: string;
  i, j, k: Integer;
  Section: string;
  SectionsList: TStringList;
  TempPack: TStringPack;
  HasError: Boolean;
begin
  IniPath := ExtractFilePath(ParamStr(0)) + 'strings.ini';
  if not FileExists(IniPath) then
  begin
    ShowMessage('Error: "strings.ini" is missing in the executable folder!');
    Exit;
  end;

  Ini := TMemIniFile.Create(IniPath);
  SectionsList := TStringList.Create;
  try
    Ini.ReadSections(SectionsList);
    SetLength(StringDatabase, 0);
    j := 0;
    i := 0;
    
    while i < SectionsList.Count do
    begin
      Section := SectionsList[i];
      if (Section <> '') and (UpperCase(Section) <> 'SETUP') then
      begin
        FillChar(TempPack, SizeOf(TempPack), 0);
        TempPack.ProductName := Ini.ReadString(Section, 'Name', 'Unknown String Pack');
        TempPack.StringCount := Ini.ReadInteger(Section, 'StringCount', 6);
        HasError := False;

        k := 1;
        while k <= TempPack.StringCount do
        begin
          TempPack.Strings[k].Gauge := Ini.ReadFloat(Section, 'G' + IntToStr(k), 0.0);
          TempPack.Strings[k].UnitWeight := Ini.ReadFloat(Section, 'W' + IntToStr(k), 0.0);
          if (TempPack.Strings[k].Gauge <= 0.0) or (TempPack.Strings[k].UnitWeight <= 0.0) then HasError := True;
          Inc(k);
        end;

        if not HasError then
        begin
          SetLength(StringDatabase, j + 1);
          StringDatabase[j] := TempPack;
          Inc(j);
        end;
      end;
      Inc(i);
    end;
  finally
    SectionsList.Free;
    Ini.Free;
  end;
end;

procedure TForm1.LoadTuningPresets;
var
  Ini: TMemIniFile;
  IniPath: string;
  TuningCount, i, k: Integer;
  Section: string;
begin
  IniPath := ExtractFilePath(ParamStr(0)) + 'tunings.ini';
  if not FileExists(IniPath) then
  begin
    ShowMessage('Error: "tunings.ini" is missing! Running in Custom mode only.');
    Exit;
  end;

  Ini := TMemIniFile.Create(IniPath);
  try
    TuningCount := Ini.ReadInteger('Setup', 'TuningCount', 0);
    SetLength(TuningPresets, TuningCount);
    ComboInstrument.Items.Clear;

    i := 0;
    while i < TuningCount do
    begin
      Section := 'Tuning_' + IntToStr(i);
      TuningPresets[i].Name := Ini.ReadString(Section, 'Name', 'Unnamed Tuning');
      TuningPresets[i].StringCount := Ini.ReadInteger(Section, 'StringCount', 6);
      
      k := 1;
      while k <= TuningPresets[i].StringCount do
      begin
        TuningPresets[i].Notes[k] := Ini.ReadString(Section, 'N' + IntToStr(k), 'E4');
        Inc(k);
      end;
      
      ComboInstrument.Items.Add(TuningPresets[i].Name);
      Inc(i);
    end;
    
    ComboInstrument.Items.Add('Custom / User-Defined...');
    ComboInstrument.ItemIndex := 0;
  finally
    Ini.Free;
  end;
end;

function TForm1.CalculateFrequency(SemitonesFromA4: Integer; BaseA4: Double): Double;
begin
  Result := BaseA4 * Power(2.0, SemitonesFromA4 / 12.0);
end;

function TForm1.CalculateTension(UnitWeight, ScaleLength, Frequency: Double): Double;
begin
  Result := (UnitWeight * Sqr(2 * ScaleLength * Frequency)) / 386.4;
end;

// FIX: Spalten-Indizes korrigiert
procedure TForm1.SetupGridHeaders;
begin
  GridResults.Cells[0, 0] := 'Product / Pack Name';
  GridResults.Cells[1, 0] := 'Tuning';
  GridResults.Cells[2, 0] := 'Frequency (Hz)';
  GridResults.Cells[3, 0] := 'String Position';
  GridResults.Cells[4, 0] := 'Exact Gauge (Inch / mm)';
  
  if CheckISO.Checked then
    GridResults.Cells[5, 0] := 'Tension (kg / N)'
  else
    GridResults.Cells[5, 0] := 'Tension (lbs)';
    
  GridResults.Cells[6, 0] := 'Scale (Inches)';
  GridResults.Cells[7, 0] := 'Tension Visual Curve';
end;

function TForm1.NoteNameToSemitones(Note: string): Integer;
var
  CleanNote: string;
  Octave, Semi: Integer;
begin
  Result := -29;
  CleanNote := UpperCase(Trim(Note));
  if CleanNote = '' then Exit;

  if TryStrToInt(CleanNote[Length(CleanNote)], Octave) then
    Delete(CleanNote, Length(CleanNote), 1)
  else
    Octave := 4;

  if (CleanNote = 'C')  then Semi := 0  else
  if (CleanNote = 'C#') or (CleanNote = 'DB') then Semi := 1  else
  if (CleanNote = 'D')  then Semi := 2  else
  if (CleanNote = 'D#') or (CleanNote = 'EB') then Semi := 3  else
  if (CleanNote = 'E')  then Semi := 4  else
  if (CleanNote = 'F')  then Semi := 5  else
  if (CleanNote = 'F#') or (CleanNote = 'GB') then Semi := 6  else
  if (CleanNote = 'G')  then Semi := 7  else
  if (CleanNote = 'G#') or (CleanNote = 'AB') then Semi := 8  else
  if (CleanNote = 'A')  then Semi := 9  else
  if (CleanNote = 'A#') or (CleanNote = 'BB') then Semi := 10 else
  if (CleanNote = 'B')  or (CleanNote = 'H')  then Semi := 11 else
    Semi := 9;

  Result := (Octave - 4) * 12 + (Semi - 9);
end;

// FIX: Array-Zuweisung einzeln über Indizes abgewickelt
function TForm1.TransposeNoteName(Note: string; Steps: Integer): string;
var
  TotalSemi, NewOctave, NewSemi: Integer;
  NotesArray: array[0..11] of string;
begin
  if Steps = 0 then Exit(Note);
  NotesArray[0] := 'C';  NotesArray[1] := 'C#'; NotesArray[2] := 'D';  NotesArray[3] := 'D#';
  NotesArray[4] := 'E';  NotesArray[5] := 'F';  NotesArray[6] := 'F#'; NotesArray[7] := 'G';
  NotesArray[8] := 'G#'; NotesArray[9] := 'A';  NotesArray[10] := 'A#'; NotesArray[11] := 'B';
  
  TotalSemi := NoteNameToSemitones(Note) + 57 + Steps;
  if TotalSemi < 0 then Exit(Note);
  
  NewOctave := TotalSemi div 12;
  NewSemi := TotalSemi mod 12;
  Result := NotesArray[NewSemi] + IntToStr(NewOctave);
end;
procedure TForm1.FillCustomDefaults;
var
  i: Integer;
begin
  if SpinStrings.Value >= 4 then
  begin
    if SpinStrings.Value <= 5 then
    begin
      if SpinStrings.Value >= 1 then GridResults.Cells[1, 1] := 'G2';
      if SpinStrings.Value >= 2 then GridResults.Cells[1, 2] := 'D2';
      if SpinStrings.Value >= 3 then GridResults.Cells[1, 3] := 'A1';
      if SpinStrings.Value >= 4 then GridResults.Cells[1, 4] := 'E1';
      if SpinStrings.Value >= 5 then GridResults.Cells[1, 5] := 'B0';
    end
    else
    begin
      if SpinStrings.Value >= 1 then GridResults.Cells[1, 1] := 'E4';
      if SpinStrings.Value >= 2 then GridResults.Cells[1, 2] := 'B3';
      if SpinStrings.Value >= 3 then GridResults.Cells[1, 3] := 'G3';
      if SpinStrings.Value >= 4 then GridResults.Cells[1, 4] := 'D3';
      if SpinStrings.Value >= 5 then GridResults.Cells[1, 5] := 'A2';
      if SpinStrings.Value >= 6 then GridResults.Cells[1, 6] := 'E2';
      if SpinStrings.Value >= 7 then GridResults.Cells[1, 7] := 'B1';
      if SpinStrings.Value >= 8 then GridResults.Cells[1, 8] := 'F#1';
    end;

    i := 8;
    while i < SpinStrings.Value do
    begin
      GridResults.Cells[1, i + 1] := 'E2';
      Inc(i);
    end;
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  Col: Integer;
begin
  DefaultFormatSettings.DecimalSeparator := '.';
  InitializeDatabase;
  LoadTuningPresets;
  
  GridResults.ColCount := 8;
  GridResults.RowCount := 7;
  GridResults.Options := GridResults.Options + [goEditing, goColSizing];
  SetupGridHeaders;

  LabelRecommendation.AutoSize := False;
  LabelRecommendation.WordWrap := True;
  LabelRecommendation.Height := 45;

  // SYSTEM FARB-OVERRIDE FOR DARK MODE
  LabelISO.Font.Color := clWhite;
  LabelTranspose.Font.Color := clWhite;
  LabelPitch.Font.Color := clWhite;
  LabelRecommendation.Font.Color := clWhite;
  LabelScaleTreble.Font.Color := clWhite;
  LabelScaleBass.Font.Color := clWhite;
  LabelBaseGuitar.Font.Color := clWhite;
  LabelBaseBass.Font.Color := clWhite;
  
  // LEUCHTENDES SIGNALROT: Zwingt den Warnhinweis auf der Form in eine unübersehbare Farbe
  LabelProNotice.Font.Color := TColor($4040FF);

  ComboTuning.Items.Clear;
  ComboTuning.Items.Add('Standard (Profile Preset)');
  ComboTuning.Items.Add('Drop Modifier (Lowest String -2 ST)');
  ComboTuning.ItemIndex := 0;

  EditScaleTreble.Text := '25.5';
  EditScaleBass.Text := '25.5';
  SpinStrings.Value := 6;
  SpinTranspose.Value := 0;
  SpinPitch.Value := 440;
  FillCustomDefaults;

  Col := 0;
  while Col < GridResults.ColCount do
  begin
    GridResults.AutoSizeColumn(Col);
    if Col = 0 then GridResults.ColWidths[Col] := 250;
    if Col = 7 then GridResults.ColWidths[Col] := 220;
    Inc(Col);
  end;
end;

procedure TForm1.SpinStringsChange(Sender: TObject);
begin
  if ComboInstrument.ItemIndex = ComboInstrument.Items.Count - 1 then 
  begin
    GridResults.RowCount := SpinStrings.Value + 1;
    SetupGridHeaders;
    FillCustomDefaults;
  end;
end;

procedure TForm1.BtnCalculateClick(Sender: TObject);
type
  TPackResult = record
    PackIndex: Integer;
    Variance: Double;
  end;
var
  ScaleTreble, ScaleBass, CurrentScale, CurrentA4, ExtGauge: Double;
  Layout: array of TStringConfig;
  StringsCount: Integer;
  i, p, m, n, Col: Integer;
  Freq, CurrentTension, TotalPackVariance, TotalSumTension: Double;
  IsCustom, IsBass: Boolean;
  FS: TFormatSettings;
  PackResults: array of TPackResult;
  TempResult: TPackResult;
  ValidPacksCount: Integer;
  BestPackIndex: Integer;
  OutputTensionString, GaugeString, TotalString, WarningMsg, DialogMsg: string;
  BaseTension, TensionDiff, Turns: Double;
  TurnsStr: string;
begin
  FSuppressDialog := False;
  FS := DefaultFormatSettings;
  FS.DecimalSeparator := '.';

  if not TryStrToFloat(EditScaleTreble.Text, ScaleTreble, FS) or
     not TryStrToFloat(EditScaleBass.Text, ScaleBass, FS) then
  begin
    ShowMessage('Please enter valid numeric values for Treble and Bass scales (e.g., 25.5).');
    Exit;
  end;

  CurrentA4 := SpinPitch.Value;
  IsCustom := (ComboInstrument.ItemIndex = ComboInstrument.Items.Count - 1);
  
  if IsCustom then 
    StringsCount := SpinStrings.Value 
  else
    StringsCount := TuningPresets[ComboInstrument.ItemIndex].StringCount;
    
  SpinStrings.Value := StringsCount;
  SetLength(Layout, StringsCount);

  IsBass := False;

  if IsCustom then
  begin
    i := 0;
    while i < StringsCount do
    begin
      Layout[i].NoteName := Trim(GridResults.Cells[1, i + 1]);
      Layout[i].SemitonesFromA4 := NoteNameToSemitones(Layout[i].NoteName);
      if Layout[i].SemitonesFromA4 < -25 then Layout[i].TargetTension := 40.0 else Layout[i].TargetTension := 15.0;
      if Layout[i].SemitonesFromA4 < -20 then IsBass := True;
      Inc(i);
    end;
  end;

  if not IsCustom then
  begin
    i := 0;
    while i < StringsCount do
    begin
      Layout[i].NoteName := TuningPresets[ComboInstrument.ItemIndex].Notes[i + 1];
      Layout[i].SemitonesFromA4 := NoteNameToSemitones(Layout[i].NoteName);
      
      if Layout[i].SemitonesFromA4 < -25 then 
        Layout[i].TargetTension := 40.0 
      else 
        Layout[i].TargetTension := 15.0;
        
      if Layout[i].SemitonesFromA4 < -20 then IsBass := True;
      Inc(i);
    end;

    if ComboTuning.ItemIndex = 1 then
    begin
      m := StringsCount - 1;
      Layout[m].SemitonesFromA4 := Layout[m].SemitonesFromA4 - 2;
      Layout[m].NoteName := Layout[m].NoteName + ' (Drop)';
      Layout[m].TargetTension := Layout[m].TargetTension + 1.0;
    end;
  end;

  i := 0;
  while i < StringsCount do
  begin
    Layout[i].SemitonesFromA4 := Layout[i].SemitonesFromA4 + SpinTranspose.Value;
    Inc(i);
  end;

  SetLength(PackResults, Length(StringDatabase));
  ValidPacksCount := 0;
  p := 0;

  while p < Length(StringDatabase) do
  begin
    if StringDatabase[p].StringCount = StringsCount then
    begin
      TotalPackVariance := 0.0;
      i := 0;

      while i < StringsCount do
      begin
        if StringsCount > 1 then
          CurrentScale := ScaleTreble + (ScaleBass - ScaleTreble) * (i / (StringsCount - 1))
        else
          CurrentScale := ScaleTreble;

        Freq := CalculateFrequency(Layout[i].SemitonesFromA4, CurrentA4);
        CurrentTension := CalculateTension(StringDatabase[p].Strings[i+1].UnitWeight, CurrentScale, Freq);
        TotalPackVariance := TotalPackVariance + Abs(CurrentTension - Layout[i].TargetTension);
        Inc(i);
      end;

      PackResults[ValidPacksCount].PackIndex := p;
      PackResults[ValidPacksCount].Variance := TotalPackVariance;
      Inc(ValidPacksCount);
    end;
    Inc(p);
  end;

  if ValidPacksCount = 0 then
  begin
    LabelRecommendation.Caption := 'NO STRINGS FOUND FOR THIS STRING COUNT!';
    LabelRecommendation.Font.Color := clRed;
    GridResults.RowCount := 1;
    SetupGridHeaders;
    Exit;
  end;

  m := 0;
  while m < ValidPacksCount - 1 do
  begin
    n := m + 1;
    while n < ValidPacksCount do
    begin
      if (PackResults[m].Variance > PackResults[n].Variance) or 
         (SameValue(PackResults[m].Variance, PackResults[n].Variance, 0.0001) and 
          (StringDatabase[PackResults[m].PackIndex].ProductName > StringDatabase[PackResults[n].PackIndex].ProductName)) then
      begin
        TempResult := PackResults[m];
        PackResults[m] := PackResults[n];
        PackResults[n] := TempResult;
      end;
      Inc(n);
    end;
    Inc(m);
  end;

  BestPackIndex := PackResults[0].PackIndex;

  TotalSumTension := 0.0;
  i := 0;
  while i < StringsCount do
  begin
    if StringsCount > 1 then
      CurrentScale := ScaleTreble + (ScaleBass - ScaleTreble) * (i / (StringsCount - 1))
    else
      CurrentScale := ScaleTreble;
    Freq := CalculateFrequency(Layout[i].SemitonesFromA4, CurrentA4);
    TotalSumTension := TotalSumTension + CalculateTension(StringDatabase[BestPackIndex].Strings[i+1].UnitWeight, CurrentScale, Freq);
    Inc(i);
  end;

  // EXPERTEN-EINSTELLUNG: Werte aus GUI auslesen
  if IsBass then
    TryStrToFloat(EditBaseBass.Text, BaseTension, FS)
  else
    TryStrToFloat(EditBaseGuitar.Text, BaseTension, FS);

  TensionDiff := TotalSumTension - BaseTension;
  Turns := Abs(TensionDiff) / 10.0;
  
  if Abs(TensionDiff) < 3.0 then
    WarningMsg := ' (Neck Tension OK - No setup changes needed)'
  else if TensionDiff > 0 then
  begin
    TurnsStr := FloatToStrF(Turns, ffFixed, 7, 1);
    WarningMsg := ' [TRUSS ROD: TIGHTEN by approx. ' + TurnsStr + ' quarter-turns clockwise]';
  end
  else
  begin
    TurnsStr := FloatToStrF(Turns, ffFixed, 7, 1);
    WarningMsg := ' [TRUSS ROD: LOOSEN by approx. ' + TurnsStr + ' quarter-turns counter-clockwise]';
  end;

  if CheckISO.Checked then
    TotalString := FloatToStrF(TotalSumTension * 0.45359237, ffFixed, 7, 1) + ' kg (' + 
                   FloatToStrF(TotalSumTension * 0.45359237 * 9.80665, ffFixed, 7, 0) + ' N)'
  else
    TotalString := FloatToStrF(TotalSumTension, ffFixed, 7, 1) + ' lbs';

  LabelRecommendation.Caption := 'Top Recommendation: ' + StringDatabase[BestPackIndex].ProductName + 
                                  LineEnding + 'Total Set Tension: ' + TotalString + WarningMsg;

  GridResults.RowCount := 1 + (StringsCount * Min(5, ValidPacksCount));
  SetupGridHeaders;

  DialogMsg := '=== EVALUATED PACKS (SORTED BY BEST FIT) ===' + LineEnding + LineEnding;

  p := 0;
  m := 1; 
  while (p < ValidPacksCount) and (p < 5) do 
  begin
    BestPackIndex := PackResults[p].PackIndex;
    
    TotalString := '';
    i := 0;
    while i < StringsCount do
    begin
      if StringsCount > 1 then CurrentScale := ScaleTreble + (ScaleBass - ScaleTreble) * (i / (StringsCount - 1)) else CurrentScale := ScaleTreble;
      Freq := CalculateFrequency(Layout[i].SemitonesFromA4, CurrentA4);
      CurrentTension := CalculateTension(StringDatabase[BestPackIndex].Strings[i+1].UnitWeight, CurrentScale, Freq);
      TotalString := TotalString + FloatToStrF(CurrentTension, ffFixed, 7, 2) + ',';
      Inc(i);
    end;

    i := 0;
    while i < StringsCount do
    begin
      if StringsCount > 1 then
        CurrentScale := ScaleTreble + (ScaleBass - ScaleTreble) * (i / (StringsCount - 1))
      else
        CurrentScale := ScaleTreble;

      Freq := CalculateFrequency(Layout[i].SemitonesFromA4, CurrentA4);
      CurrentTension := CalculateTension(StringDatabase[BestPackIndex].Strings[i+1].UnitWeight, CurrentScale, Freq);

      if CheckISO.Checked then
        OutputTensionString := FloatToStrF(CurrentTension * 0.45359237, ffFixed, 7, 1) + ' kg (' + 
                              FloatToStrF(CurrentTension * 0.45359237 * 9.80665, ffFixed, 7, 0) + ' N)'
      else
        OutputTensionString := FloatToStrF(CurrentTension, ffFixed, 7, 1) + ' lbs';

      ExtGauge := StringDatabase[BestPackIndex].Strings[i+1].Gauge;
      GaugeString := FloatToStrF(ExtGauge, ffFixed, 7, 3) + '" (' + 
                     FloatToStrF(ExtGauge * 25.4, ffFixed, 7, 2) + ' mm)';

      GridResults.Cells[0, m] := StringDatabase[BestPackIndex].ProductName + ' [#' + IntToStr(p+1) + ']';
      GridResults.Cells[1, m] := TransposeNoteName(Layout[i].NoteName, SpinTranspose.Value);
      GridResults.Cells[2, m] := FloatToStrF(Freq, ffFixed, 7, 2);
      GridResults.Cells[3, m] := 'String ' + IntToStr(i + 1);
      GridResults.Cells[4, m] := GaugeString;
      GridResults.Cells[5, m] := OutputTensionString;
      GridResults.Cells[6, m] := FloatToStrF(CurrentScale, ffFixed, 7, 2);
      GridResults.Cells[7, m] := TotalString;
      
      Inc(i);
      Inc(m);
    end;

    TotalSumTension := 0.0;
    i := 0;
    while i < StringsCount do
    begin
      if StringsCount > 1 then CurrentScale := ScaleTreble + (ScaleBass - ScaleTreble) * (i / (StringsCount - 1)) else CurrentScale := ScaleTreble;
      Freq := CalculateFrequency(Layout[i].SemitonesFromA4, CurrentA4);
      TotalSumTension := TotalSumTension + CalculateTension(StringDatabase[BestPackIndex].Strings[i+1].UnitWeight, CurrentScale, Freq);
      Inc(i);
    end;

    // Alternative Sätze für das Dialogfenster auswerten
    if IsBass then
    begin
      if (StringsCount >= 5) and (TotalSumTension > 235.0) then WarningMsg := 'WARNING: OVERLOAD!'
      else if (StringsCount = 4) and (TotalSumTension > 185.0) then WarningMsg := 'WARNING: OVERLOAD!'
      else WarningMsg := 'OK';
    end
    else
    begin
      if TotalSumTension > 155.0 then WarningMsg := 'DANGEROUS!' else WarningMsg := 'OK';
    end;

    if CheckISO.Checked then OutputTensionString := FloatToStrF(TotalSumTension * 0.45359237, ffFixed, 7, 1) + ' kg'
    else OutputTensionString := FloatToStrF(TotalSumTension, ffFixed, 7, 1) + ' lbs';

    DialogMsg := DialogMsg + '#' + IntToStr(p + 1) + ': ' + StringDatabase[BestPackIndex].ProductName + LineEnding +
                 '    -> Tension: ' + OutputTensionString + ' | Neck Status: ' + WarningMsg + ' | Avg. Variance: ' +
                 FloatToStrF(PackResults[p].Variance / StringsCount, ffFixed, 7, 1) + ' lbs/string' + LineEnding + LineEnding;

    Inc(p);
  end;

  Col := 0;
  while Col < GridResults.ColCount do
  begin
    GridResults.AutoSizeColumn(Col);
    if Col = 0 then GridResults.ColWidths[Col] := GridResults.ColWidths[Col] + 20;
    if Col = 7 then GridResults.ColWidths[Col] := 220;
    Inc(Col);
  end;
  
  if not FSuppressDialog then ShowMessage(DialogMsg);
end;
procedure TForm1.GridResultsDrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
var
  CellValue: string;
  TensionValue: Double;
  IsBass: Boolean;
  Grid: TStringGrid;
  MinGreen, MaxGreen, MaxScale, SingleTension: Double;
  TensionList: TStringList;
  h, TotalStringsInPack, StringIdx, PixelX, PixelY: Integer;
begin
  Grid := Sender as TStringGrid;
  
  if (ARow = 0) or (ACol = 0) then
  begin
    Grid.Canvas.Brush.Color := TColor($323232);
    Grid.Canvas.FillRect(Rect);
    Grid.Canvas.Font.Color := clWhite;
    Grid.Canvas.TextRect(Rect, Rect.Left + 4, Rect.Top + 4, Grid.Cells[ACol, ARow]);
    Exit;
  end;

  if gdSelected in State then Exit;

  IsBass := (ComboInstrument.ItemIndex = 3) or (ComboInstrument.ItemIndex = 4) or 
            ((ComboInstrument.ItemIndex >= 14) and (ComboInstrument.ItemIndex <= 17));

  if ACol = 5 then
  begin
    CellValue := Grid.Cells[ACol, ARow];
    
    if CheckISO.Checked then
    begin
      if Pos(' kg', CellValue) > 0 then CellValue := Copy(CellValue, 1, Pos(' kg', CellValue) - 1);
      if IsBass then begin MinGreen := 15.4; MaxGreen := 20.4; end
      else begin MinGreen := 5.9; MaxGreen := 8.6; end;
    end
    else
    begin
      CellValue := StringReplace(CellValue, ' lbs', '', [rfReplaceAll]);
      if IsBass then begin MinGreen := 34.0; MaxGreen := 45.0; end
      else begin MinGreen := 13.0; MaxGreen := 19.0; end;
    end;

    if TryStrToFloat(CellValue, TensionValue) then
    begin
      if TensionValue < MinGreen then
        Grid.Canvas.Brush.Color := TColor($50321E)
      else if TensionValue > MaxGreen then
        Grid.Canvas.Brush.Color := TColor($1E1E50)
      else
        Grid.Canvas.Brush.Color := TColor($1E461E);

      Grid.Canvas.FillRect(Rect);
      Grid.Canvas.Font.Color := clWhite;
      Grid.Canvas.TextRect(Rect, Rect.Left + 4, Rect.Top + 4, Grid.Cells[ACol, ARow]);
    end;
  end
  else if ACol = 7 then
  begin
    CellValue := Grid.Cells[ACol, ARow];
    Grid.Canvas.Brush.Color := TColor($151515);
    Grid.Canvas.FillRect(Rect);
    
    if Trim(CellValue) <> '' then
    begin
      TensionList := TStringList.Create;
      try
        TensionList.CommaText := CellValue;
        TotalStringsInPack := TensionList.Count;
        StringIdx := (ARow - 1) mod TotalStringsInPack;
        
        if IsBass then MaxScale := 60.0 else MaxScale := 25.0;

        Grid.Canvas.Pen.Color := TColor($333333);
        Grid.Canvas.Pen.Style := psDot;
        Grid.Canvas.MoveTo(Rect.Left, Rect.Top + (Rect.Height div 2));
        Grid.Canvas.LineTo(Rect.Right, Rect.Top + (Rect.Height div 2));

        Grid.Canvas.Pen.Color := TColor($2E7D32);
        Grid.Canvas.Pen.Style := psSolid;
        Grid.Canvas.Pen.Width := 2;

        h := 0;
        while h < TotalStringsInPack do
        begin
          if TryStrToFloat(TensionList[h], SingleTension) then
          begin
            if TotalStringsInPack > 1 then
              PixelX := Rect.Left + 15 + Trunc((Rect.Width - 30) * (h / (TotalStringsInPack - 1)))
            else
              PixelX := Rect.Left + (Rect.Width div 2);

            PixelY := Rect.Top + Rect.Height - 6 - Trunc((Rect.Height - 12) * (SingleTension / MaxScale));
            
            if PixelY < Rect.Top + 2 then PixelY := Rect.Top + 2;
            if PixelY > Rect.Bottom - 2 then PixelY := Rect.Bottom - 2;

            if h = 0 then
              Grid.Canvas.MoveTo(PixelX, PixelY)
            else
              Grid.Canvas.LineTo(PixelX, PixelY);

            if h = StringIdx then
            begin
              Grid.Canvas.Brush.Color := clWhite;
              Grid.Canvas.Pen.Width := 1;
              Grid.Canvas.Rectangle(PixelX - 3, PixelY - 3, PixelX + 3, PixelY + 3);
              Grid.Canvas.Pen.Width := 2;
              Grid.Canvas.Pen.Color := TColor($2E7D32);
            end;
          end;
          Inc(h);
        end;
      finally
        TensionList.Free;
      end;
    end;
    Grid.Canvas.Pen.Width := 1;
  end
  else
  begin
    Grid.Canvas.Brush.Color := TColor($212121);
    Grid.Canvas.FillRect(Rect);
    Grid.Canvas.Font.Color := clWhite;
    Grid.Canvas.TextRect(Rect, Rect.Left + 4, Rect.Top + 4, Grid.Cells[ACol, ARow]);
  end;
end;

procedure TForm1.BtnExportClick(Sender: TObject);
var
  CSV: TStringList;
  RowText: string;
  Col, Row: Integer;
  SaveDialog: TSaveDialog;
begin
  if GridResults.RowCount <= 1 then
  begin
    ShowMessage('Please execute a calculation first.');
    Exit;
  end;

  SaveDialog := TSaveDialog.Create(Self);
  CSV := TStringList.Create;
  try
    SaveDialog.Title := 'Export String Table';
    SaveDialog.Filter := 'CSV File (*.csv)|*.csv';
    SaveDialog.DefaultExt := 'csv';
    SaveDialog.FileName := 'String_Tension_Calculation.csv';

    if SaveDialog.Execute then
    begin
      Row := 0;
      while Row < GridResults.RowCount do
      begin
        RowText := '';
        Col := 0;
        while Col < GridResults.ColCount do
        begin
          RowText := RowText + GridResults.Cells[Col, Row] + ';';
          Inc(Col);
        end;
        if RowText <> '' then Delete(RowText, Length(RowText), 1);
        CSV.Add(RowText);
        Inc(Row);
      end;
      CSV.SaveToFile(SaveDialog.FileName);
      ShowMessage('Successfully exported!');
    end;
  finally
    SaveDialog.Free;
    CSV.Free;
  end;
end;

procedure TForm1.BtnSaveTuningClick(Sender: TObject);
var
  Ini: TMemIniFile;
  IniPath, CustomName, Section, CleanNote: string;
  TuningCount, i: Integer;
  IsConfirmed: Boolean;
begin
  CustomName := 'Guitar: 6-String MyCustomTuning';
  IsConfirmed := InputQuery('Save Custom Tuning', 'Enter a descriptive name for this tuning profile:', CustomName);
  
  if not IsConfirmed then Exit;
  if Trim(CustomName) = '' then Exit;

  IniPath := ExtractFilePath(ParamStr(0)) + 'tunings.ini';
  Ini := TMemIniFile.Create(IniPath);
  try
    TuningCount := Ini.ReadInteger('Setup', 'TuningCount', 0);
    Section := 'Tuning_' + IntToStr(TuningCount);

    Ini.WriteString(Section, 'Name', CustomName);
    Ini.WriteInteger(Section, 'StringCount', SpinStrings.Value);

    i := 0;
    while i < SpinStrings.Value do
    begin
      CleanNote := Trim(GridResults.Cells[1, i + 1]);
      if Pos(' ', CleanNote) > 0 then CleanNote := Copy(CleanNote, 1, Pos(' ', CleanNote) - 1);
      Ini.WriteString(Section, 'N' + IntToStr(i + 1), CleanNote);
      Inc(i);
    end;

    Ini.WriteInteger('Setup', 'TuningCount', TuningCount + 1);
    Ini.UpdateFile;
    ShowMessage('Tuning preset saved successfully!');
    LoadTuningPresets;
  finally
    Ini.Free;
  end;
end;

// PRINT PDF ENGINE: Generiert ein HTML-Datenblatt inklusive aller Erklärungen für den PDF-Druck
// PRINT PDF ENGINE: Generiert ein HTML-Datenblatt inklusive der physikalischen Differenz-Erklärung
// PRINT PDF ENGINE: Generiert ein HTML-Datenblatt inklusive Anleitung zur Basis-Ermittlung und Haftungsausschluss
procedure TForm1.CheckISOChange(Sender: TObject);
begin
  // Re-run the calculation so the grid tension column, totals and
  // colour thresholds switch between lbs and kg/N. Suppress the summary
  // dialog so toggling units does not pop a modal on every click.
  if GridResults.RowCount > 1 then
  begin
    FSuppressDialog := True;
    try
      BtnCalculateClick(Self);
    finally
      FSuppressDialog := False;
    end;
  end
  else
    SetupGridHeaders;
end;

procedure TForm1.BtnPrintPDFClick(Sender: TObject);
var
  HTML: TStringList;
  HTMLPath: string;
  Row, Col: Integer;
begin
  if GridResults.RowCount <= 1 then
  begin
    ShowMessage('Please execute a calculation first to generate a report.');
    Exit;
  end;

  HTMLPath := ExtractFilePath(ParamStr(0)) + 'Workshop_Report.html';
  HTML := TStringList.Create;
  try
    HTML.Add('<!DOCTYPE html><html><head><meta charset="UTF-8">');
    HTML.Add('<title>String Tension Workshop Report</title>');
    HTML.Add('<style>');
    HTML.Add('  body { font-family: "Segoe UI", Arial, sans-serif; margin: 40px; color: #333; line-height: 1.5; }');
    HTML.Add('  h1 { color: #1b5e20; border-bottom: 2px solid #2e7d32; padding-bottom: 10px; font-size: 26px; }');
    HTML.Add('  h2 { color: #2e7d32; margin-top: 30px; font-size: 18px; border-bottom: 1px solid #ddd; padding-bottom: 5px; }');
    HTML.Add('  .meta-box { background: #f5f5f5; padding: 15px; border-left: 5px solid #2e7d32; margin-bottom: 20px; font-size: 14px; }');
    HTML.Add('  .info-box { background: #e8f5e9; border: 1px solid #c8e6c9; padding: 15px; margin-top: 20px; font-size: 14px; border-radius: 4px; }');
    HTML.Add('  .physics-box { background: #fffde7; border: 1px solid #fff59d; padding: 15px; margin-top: 20px; font-size: 13px; border-radius: 4px; color: #5d4037; }');
    HTML.Add('  .disclaimer-box { background: #ffebee; border: 1px solid #ef9a9a; padding: 15px; margin-top: 20px; font-size: 13px; border-radius: 4px; color: #b71c1c; }');
    HTML.Add('  table { width: 100%; border-collapse: collapse; margin-top: 15px; font-size: 13px; }');
    HTML.Add('  th { background: #2e7d32; color: #fff; padding: 10px; text-align: left; }');
    HTML.Add('  td { padding: 8px 10px; border-bottom: 1px solid #ddd; }');
    HTML.Add('  tr:nth-child(even) { background: #fafafa; }');
    HTML.Add('  .print-btn { background: #2e7d32; color: white; border: none; padding: 10px 20px; font-weight: bold; cursor: pointer; border-radius: 4px; font-size: 14px; }');
    HTML.Add('  @media print { .print-btn { display: none; } body { margin: 10px; } }');
    HTML.Add('</style></head><body>');

    HTML.Add('<h1>String Tension Setup & Workshop Report</h1>');
    HTML.Add('<button class="print-btn" onclick="window.print()">Print Report / Save as PDF</button>');

    // 1. Meta-Informationen
    HTML.Add('<div class="meta-box">');
    HTML.Add('  <strong>Instrument Profile:</strong> ' + ComboInstrument.Text + '<br>');
    HTML.Add('  <strong>Tuning Modifier:</strong> ' + ComboTuning.Text + '<br>');
    HTML.Add('  <strong>Concert Pitch Ref:</strong> A4 = ' + SpinPitch.Text + ' Hz<br>');
    HTML.Add('  <strong>Scale Lengths:</strong> Treble: ' + EditScaleTreble.Text + '" | Bass: ' + EditScaleBass.Text + '"<br>');
    HTML.Add('  <strong>Target Base Reference:</strong> ' + EditBaseGuitar.Text + ' lbs (Guitar) / ' + EditBaseBass.Text + ' lbs (Bass)<br>');
    HTML.Add('  <strong>Evaluation Summary:</strong> ' + LabelRecommendation.Caption);
    HTML.Add('</div>');

    // 2. Physikalische Erläuterungen & Anleitung zur Basis-Ermittlung
    HTML.Add('<h2>Physics & Mechanics: Understanding the Truss Rod Guidance</h2>');
    HTML.Add('<div class="physics-box">');
    HTML.Add('  <strong>How to interpret the calculation:</strong><br>');
    HTML.Add('  This adjustment guide is based on a <strong>relative differential calculation</strong>. It assumes that the instrument ');
    HTML.Add('  was perfectly adjusted, holding an ideal neck relief and action with your previous string setup.<br><br>');
    HTML.Add('  <strong>How to determine your proper Base Tension:</strong><br>');
    HTML.Add('  To find your instrument''s personal zero-point, select the exact tuning and string pack that your instrument ');
    HTML.Add('  was previously set up with. Run the calculation. Take the resulting "Total Set Tension" value and enter it into the ');
    HTML.Add('  "Base Tension" expert field. This establishes your correct physical baseline.<br><br>');
    HTML.Add('  The program then measures the weight difference of your new setup. In luthier mechanics, a tension change of ');
    HTML.Add('  <strong>10 lbs (approx. 4.5 kg)</strong> alters the static balance enough to require a compensation of exactly ');
    HTML.Add('  <strong>one quarter-turn (90 degrees)</strong> of the truss rod nut to recreate the original neck relief.');
    HTML.Add('</div>');

    // 3. RECHTLICHER HAFTUNGSAUSSCHLUSS (Disclaimer)
    HTML.Add('<h2>Important Safety Disclaimer & Liability Waiver</h2>');
    HTML.Add('<div class="disclaimer-box">');
    HTML.Add('  <strong>WARNING & LEGAL DISCLAIMER:</strong><br>');
    HTML.Add('  This report provides purely mathematical guidelines based on theoretical formulas and empirical workshop averages. ');
    HTML.Add('  The author and creator of this software are <strong>in no way responsible or liable for any damages</strong> to your instrument, ');
    HTML.Add('  neck, truss rod, hardware, or structural integrity resulting from wrong string choices, incorrect order of installation, ');
    HTML.Add('  or improper technical adjustments. Wood is a natural material with unpredictable variations.<br><br>');
    HTML.Add('  <strong>IF YOU ARE UNSURE, LEAVE IT TO A PROFESSIONAL BY ANY MEANS.</strong> Truss rod adjustments can cause permanent ');
    HTML.Add('  structural damage if executed incorrectly. If you experience unexpected mechanical resistance, or lack the proper tools ');
    HTML.Add('  and experience, immediately stop and take your instrument to a qualified luthier or guitar technician.');
    HTML.Add('</div>');

    // 4. Konkrete Werkanweisung
    HTML.Add('<h2>Truss Rod Adjustment Instruction</h2>');
    HTML.Add('<div class="info-box">');
    HTML.Add('  <strong>Action Required:</strong> ' + LabelRecommendation.Caption + '<br><br>');
    HTML.Add('  <em>Workshop Execution Rule:</em> Always execute truss rod adjustments under full string pitch. Retune the instrument ');
    HTML.Add('  immediately after turning the nut. Let the wood settle for a few minutes before performing final action, intonation, and relief checks.');
    HTML.Add('</div>');

    // 5. Matrix der Berechnungen
    HTML.Add('<h2>Calculated Tension Profile Matrix</h2>');
    HTML.Add('<table><thead><tr>');
    
    Col := 0;
    while Col < 7 do
    begin
      HTML.Add('<th>' + GridResults.Cells[Col, 0] + '</th>');
      Inc(Col);
    end;
    HTML.Add('</tr></thead><tbody>');

    Row := 1;
    while Row < GridResults.RowCount do
    begin
      HTML.Add('<tr>');
      Col := 0;
      while Col < 7 do
      begin
        HTML.Add('<td>' + GridResults.Cells[Col, Row] + '</td>');
        Inc(Col);
      end;
      HTML.Add('</tr>');
      Inc(Row);
    end;
    HTML.Add('</tbody></table>');

    HTML.Add('</body></html>');
    HTML.Add('');
    
    HTML.SaveToFile(HTMLPath);
    OpenURL('file://' + HTMLPath);
  finally
    HTML.Free;
  end;
end;

end.
