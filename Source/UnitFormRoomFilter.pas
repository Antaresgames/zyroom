{*******************************************************************************
zyRoom project for Ryzom Summer Coding Contest 2009
Copyright (C) 2009 Misugi
http://zyroom.misulud.fr
contact@misulud.fr

Developed with Delphi 7 Personal,
this application is designed for players to view guild rooms and search items.

zyRoom is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

zyRoom is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with zyRoom.  If not, see http://www.gnu.org/licenses.
*******************************************************************************}
unit UnitFormRoomFilter;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, pngimage, ShellAPI, Spin, UnitRyzom;

type
  TFormRoomFilter = class(TForm)
    BtOK: TButton;
    GbType: TGroupBox;
    CbTypeNaturalMat: TCheckBox;
    CbTypeAnimalMat: TCheckBox;
    CbTypeCata: TCheckBox;
    CbTypeOthers: TCheckBox;
    GbQuality: TGroupBox;
    LbQualityMin: TLabel;
    LbQualityMax: TLabel;
    EdQualityMin: TSpinEdit;
    EdQualityMax: TSpinEdit;
    GbClass: TGroupBox;
    LbClassMin: TLabel;
    LbClassMax: TLabel;
    EdClassMin: TComboBox;
    EdClassMax: TComboBox;
    GbEcosys: TGroupBox;
    CbEcoPrime: TCheckBox;
    CbEcoCommon: TCheckBox;
    CbEcoDesert: TCheckBox;
    CbEcoForest: TCheckBox;
    CbEcoLakes: TCheckBox;
    CbEcoJungle: TCheckBox;
    CbTypeEquipment: TCheckBox;
    procedure BtOKClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure CbTypeAnimalMatClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    procedure EnabledGroup(AGroup: TGroupBox; AEnabled: Boolean);
    procedure LoadCurrentFilter;
    procedure SaveCurrentFilter;
  public
  end;

var
  FormRoomFilter: TFormRoomFilter;

implementation

uses UnitFormProgress, UnitFormGuild, UnitFormRoom;

{$R *.dfm}

{*******************************************************************************
Creates the form
*******************************************************************************}
procedure TFormRoomFilter.FormCreate(Sender: TObject);
begin
end;

{*******************************************************************************
Closes the form
*******************************************************************************}
procedure TFormRoomFilter.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  FormRoom.BtFilter.Down := False;
end;

{*******************************************************************************
Shows the form
*******************************************************************************}
procedure TFormRoomFilter.FormShow(Sender: TObject);
begin
  LoadCurrentFilter;
end;

{*******************************************************************************
Applies the filter
*******************************************************************************}
procedure TFormRoomFilter.BtOKClick(Sender: TObject);
var
  wGuildID: String;
begin
  SaveCurrentFilter;
  wGuildID := FormGuild.GridGuild.Cells[2, FormGuild.GridGuild.Row];
  FormProgress.ShowFormRoom(wGuildID, FormRoom.GuildRoom, GCurrentFilter);
end;

{*******************************************************************************
Changes the checkbox for natural or animal materials
*******************************************************************************}
procedure TFormRoomFilter.CbTypeAnimalMatClick(Sender: TObject);
begin
  EnabledGroup(GbEcosys, CbTypeNaturalMat.Checked or CbTypeAnimalMat.Checked);
  EnabledGroup(GbClass, CbTypeNaturalMat.Checked or CbTypeAnimalMat.Checked);
end;

{*******************************************************************************
Enables or disables all components in a groupbox
*******************************************************************************}
procedure TFormRoomFilter.EnabledGroup(AGroup: TGroupBox; AEnabled: Boolean);
var
  i: Integer;
begin
  for i := 0 to AGroup.ControlCount - 1 do begin
    AGroup.Controls[i].Enabled := AEnabled;
  end;
end;

{*******************************************************************************
Loads the current filter
*******************************************************************************}
procedure TFormRoomFilter.LoadCurrentFilter;
begin
  // Type
  CbTypeNaturalMat.Checked := (itNaturalMat in GCurrentFilter.Type_);
  CbTypeAnimalMat.Checked := (itAnimalMat in GCurrentFilter.Type_);
  CbTypeCata.Checked := (itCata in GCurrentFilter.Type_);
  CbTypeOthers.Checked := (itOthers in GCurrentFilter.Type_);
  CbTypeEquipment.Checked := (itEquipment in GCurrentFilter.Type_);

  // Quality
  EdQualityMin.Value := GCurrentFilter.QualityMin;
  EdQualityMax.Value := GCurrentFilter.QualityMax;

  // Class
  EdClassMin.ItemIndex := Ord(GCurrentFilter.ClassMin);
  EdClassMax.ItemIndex := Ord(GCurrentFilter.ClassMax);

  // Ecosystem
  CbEcoPrime.Checked := (iePrime in GCurrentFilter.Ecosystem);
  CbEcoCommon.Checked := (ieCommon in GCurrentFilter.Ecosystem);
  CbEcoDesert.Checked := (ieDesert in GCurrentFilter.Ecosystem);
  CbEcoForest.Checked := (ieForest in GCurrentFilter.Ecosystem);
  CbEcoLakes.Checked := (ieLakes in GCurrentFilter.Ecosystem);
  CbEcoJungle.Checked := (ieJungle in GCurrentFilter.Ecosystem);

  EnabledGroup(GbEcosys, CbTypeNaturalMat.Checked or CbTypeAnimalMat.Checked);
  EnabledGroup(GbClass, CbTypeNaturalMat.Checked or CbTypeAnimalMat.Checked);
end;

{*******************************************************************************
Saves the current filter
*******************************************************************************}
procedure TFormRoomFilter.SaveCurrentFilter;
begin
  // Item type
  GCurrentFilter.Type_ := [];
  if CbTypeAnimalMat.Checked then GCurrentFilter.Type_ := GCurrentFilter.Type_ + [itAnimalMat];
  if CbTypeNaturalMat.Checked then GCurrentFilter.Type_ := GCurrentFilter.Type_ + [itNaturalMat];
  if CbTypeCata.Checked then GCurrentFilter.Type_ := GCurrentFilter.Type_ + [itCata];
  if CbTypeEquipment.Checked then GCurrentFilter.Type_ := GCurrentFilter.Type_ + [itEquipment];
  if CbTypeOthers.Checked then GCurrentFilter.Type_ := GCurrentFilter.Type_ + [itOthers];

  // Item quality
  if EdQualityMax.Value < EdQualityMin.Value then EdQualityMax.Value := EdQualityMin.Value;
  GCurrentFilter.QualityMin := EdQualityMin.Value;
  GCurrentFilter.QualityMax := EdQualityMax.Value;

  // Item ecosystem
  GCurrentFilter.Ecosystem := [];
  if CbEcoPrime.Checked then GCurrentFilter.Ecosystem := GCurrentFilter.Ecosystem + [iePrime];
  if CbEcoCommon.Checked then GCurrentFilter.Ecosystem := GCurrentFilter.Ecosystem + [ieCommon];
  if CbEcoDesert.Checked then GCurrentFilter.Ecosystem := GCurrentFilter.Ecosystem + [ieDesert];
  if CbEcoForest.Checked then GCurrentFilter.Ecosystem := GCurrentFilter.Ecosystem + [ieForest];
  if CbEcoLakes.Checked then GCurrentFilter.Ecosystem := GCurrentFilter.Ecosystem + [ieLakes];
  if CbEcoJungle.Checked then GCurrentFilter.Ecosystem := GCurrentFilter.Ecosystem + [ieJungle];

  // Item class
  if EdClassMax.ItemIndex < EdClassMin.ItemIndex then EdClassMax.ItemIndex := EdClassMin.ItemIndex;
  GCurrentFilter.ClassMin := TItemClass(EdClassMin.ItemIndex);
  GCurrentFilter.ClassMax := TItemClass(EdClassMax.ItemIndex);
end;

end.
