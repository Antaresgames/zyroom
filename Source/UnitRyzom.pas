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
unit UnitRyzom;

interface

uses
  Classes, SysUtils, RyzomApi, XpDOM, regexpr, UnitConfig, StrUtils;

const
  _ITEM_CATEGORY : array [0..20] of String = ('Blade', 'Hammer', 'Point', 'Shaft', 'Grip', 'Counterweight',
    'MagicFokus', 'Trigger', 'FiringPin', 'Barrel', 'Explosive', 'Jacket', 'Bullet',
    'Cloth', 'ArmorShell', 'Lining', 'Stuffing', 'ArmorClip', 'JewelSetting', 'Jewels', 'Unknown');

  _EXPR_NATURAL_MAT = '^m\d{4}dxa([pcdflj])([b-f])01\.sitem';
  _EXPR_ANIMAL_MAT = '^m\d{4}.{3}([pcdflj])([a-e])01\.sitem';
  _EXPR_EQUIPMENT = '^ic(.).*(.{2})\.sitem';
  _EXPR_EQUIPMENT_ARMOR = '^ic.a(.).*';
  _EXPR_EQUIPMENT_AMPLIFIER = '^ic.+m2ms.*';
  _EXPR_EQUIPMENT_WEAPON = '^ic.+([rm])([12]).*';
  _EXPR_EQUIPMENT_JEWEL = '^ic.j.*';
  
type
  TItemType =(itAnimalMat, itNaturalMat, itCata, itEquipment, itOthers);
  TItemTypes = set of TItemType;
  TItemClass = (icBasic, icFine, icChoice, icExcellent, icSupreme, icUnknown);
  TItemEcosystem = (ieCommon, iePrime, ieDesert, ieJungle, ieForest, ieLakes, ieUnknown);
  TItemEcosystems = set of TItemEcosystem;
  TItemEquip = (iqLightArmor, iqMediumArmor, iqHeavyArmor, iqWeaponMelee, iqWeaponRange, iqAmplifier, iqJewel, iqOthers);
  TItemWeapon = (iwOneHand, iwTwoHands);
  TItemSkin = (isSkin1, isSkin2, isSkin3, isNoSkin);
  TItemEquips = set of TItemEquip;

  TItemFilter = record
    Enabled: Boolean;
    Type_: TItemTypes;
    QualityMin: Integer;
    QualityMax: Integer;
    ClassMin: TItemClass;
    ClassMax: TItemClass;
    Ecosystem: TItemEcosystems;
    ItemName: String;
    AllWords: Boolean;
    Equipment: TItemEquips;
    CategoryIndex: Integer;
  end;
  
  TItemInfo = class(TObject)
  public
    ItemName: String;
    ItemColor: TItemColor;
    ItemQuality: Integer;
    ItemSize: Integer;
    ItemSap: Integer;
    ItemDestroyed: Boolean;
    ItemFileName: String;
    ItemClass: TItemClass;
    ItemType: TItemType;
    ItemEcosys: TItemEcosystem;
    ItemEquip: TItemEquip;
    ItemCategory1: String;
    ItemCategory2: String;
    ItemWeapon: TItemWeapon;
    ItemSkin: TItemSkin;
    ItemDesc: String;
    ItemHp: Integer;
    ItemDur: Integer;
    ItemHpb: Integer;
    ItemSab: Integer;
    ItemStb: Integer;
    ItemFob: Integer;
  end;

  TRyzom = class(TRyzomApi)
  private
    FXmlDocument: TXpObjModel;
    FCatStrings: TStringList;

    FAniroStatus: Integer;
    FArispotleStatus: Integer;
    FLeanonStatus: Integer;
  public
    constructor Create;
    destructor Destroy; override;

    procedure UpdateStatus;
    procedure GetItemInfoFromXML(ANode: TXpNode; AItemInfo: TItemInfo);
    function  CheckItem(AItemInfo: TItemInfo; AFilter: TItemFilter): Boolean;
    procedure GetItemInfoFromName(AItemInfo: TItemInfo);
    procedure SetDefaultFilter(var AFilter: TItemFilter);
    
    property AniroStatus: Integer read FAniroStatus;
    property LeanonStatus: Integer read FLeanonStatus;
    property ArispotleStatus: Integer read FArispotleStatus;
  end;


var
  GRyzomApi: TRyzom;
  GRyzomStringPack: TStringClient;
  GRegExpr: TRegExpr;
  GCurrentFilter: TItemFilter;

implementation

uses MisuDevKit;

{ TRyzom }

{*******************************************************************************
Creates the interface object
*******************************************************************************}
constructor TRyzom.Create;
var
  wCatFile: String;
begin
  inherited Create;
  FXmlDocument := TXpObjModel.Create(nil);
  FCatStrings := TStringList.Create;
  wCatFile := GConfig.CurrentPath + 'category.csv';
  if FileExists(wCatFile) then
    FCatStrings.LoadFromFile(wCatFile);
end;

{*******************************************************************************
Destroys the interface object
*******************************************************************************}
destructor TRyzom.Destroy;
begin
  FCatStrings.Free;
  FXmlDocument.Free;
  inherited;
end;

{*******************************************************************************
Returns information of an item
*******************************************************************************}
procedure TRyzom.GetItemInfoFromXML(ANode: TXpNode; AItemInfo: TItemInfo);
var
  wNode: TXpNode;
begin
  // Default values
  AItemInfo.ItemColor := icNone;
  AItemInfo.ItemQuality := -1;
  AItemInfo.ItemSize := -1;
  AItemInfo.ItemSap := -1;
  AItemInfo.ItemDestroyed := False;
  AItemInfo.ItemClass := icUnknown;
  AItemInfo.ItemHp := 0;
  
  // Name
  AItemInfo.ItemName := ANode.Text;

  // Color
  wNode := ANode.Attributes.GetNamedItem('c');
  if Assigned(wNode) then AItemInfo.ItemColor := ToItemColor(wNode.NodeValue);

  // Quality
  wNode := ANode.Attributes.GetNamedItem('q');
  if Assigned(wNode) then AItemInfo.ItemQuality := StrToInt(wNode.NodeValue);

  // Size
  wNode := ANode.Attributes.GetNamedItem('s');
  if Assigned(wNode) then AItemInfo.ItemSize := StrToInt(wNode.NodeValue);

  // Sap load
  wNode := ANode.Attributes.GetNamedItem('sap');
  if Assigned(wNode) then AItemInfo.ItemSap := StrToInt(wNode.NodeValue);

  // Destroyed / HP
  wNode := ANode.Attributes.GetNamedItem('hp');
  if Assigned(wNode) then begin
    AItemInfo.ItemHp := StrToInt(wNode.NodeValue);
    AItemInfo.ItemDestroyed := AItemInfo.ItemHp <= 1;
  end;

  // Durability
  wNode := ANode.Attributes.GetNamedItem('dur');
  if Assigned(wNode) then AItemInfo.ItemDur := StrToInt(wNode.NodeValue);

  // HP Bonus
  wNode := ANode.Attributes.GetNamedItem('hpb');
  if Assigned(wNode) then AItemInfo.ItemHpb := StrToInt(wNode.NodeValue);

  // Sap Bonus
  wNode := ANode.Attributes.GetNamedItem('sab');
  if Assigned(wNode) then AItemInfo.ItemSab := StrToInt(wNode.NodeValue);

  // Stamina Bonus
  wNode := ANode.Attributes.GetNamedItem('stb');
  if Assigned(wNode) then AItemInfo.ItemStb := StrToInt(wNode.NodeValue);

  // Focus Bonus
  wNode := ANode.Attributes.GetNamedItem('fob');
  if Assigned(wNode) then AItemInfo.ItemFob := StrToInt(wNode.NodeValue);

  // Energy
  wNode := ANode.Attributes.GetNamedItem('e');
  if Assigned(wNode) then begin
    case Ord(wNode.NodeValue[1]) of
      98:  AItemInfo.ItemClass := icBasic; {b = base}
      102: AItemInfo.ItemClass := icFine; {f = fine}
      99:  AItemInfo.ItemClass := icChoice; {c = choice}
      101: AItemInfo.ItemClass := icExcellent; {e = excelent}
      115: AItemInfo.ItemClass := icSupreme; {s = supreme}
    end;
  end;

  // Image filename
  AItemInfo.ItemFileName := Format('%s.c%dq%ds%dd%d%s',
    [AItemInfo.ItemName, Ord(AItemInfo.ItemColor), AItemInfo.ItemQuality, AItemInfo.ItemSize,
    MdkBoolToInteger(AItemInfo.ItemDestroyed), _ICON_FORMAT]);
end;

{*******************************************************************************
Updates status of the servers
*******************************************************************************}
procedure TRyzom.UpdateStatus;
var
  wResponse: TMemoryStream;
  wXpath: String;
begin
  wResponse := TMemoryStream.Create();
  try
    ApiStatus(_FORMAT_XML, wResponse);
    if FXmlDocument.LoadStream(wResponse) then begin
      wXpath := '/shard_status/shard[@shardid=''%s'']';
      FAniroStatus := FXmlDocument.DocumentElement.SelectInteger(Format(wXpath, [_SHARD_ANIRO_ID]));
      FLeanonStatus := FXmlDocument.DocumentElement.SelectInteger(Format(wXpath, [_SHARD_LEANON_ID]));
      FArispotleStatus := FXmlDocument.DocumentElement.SelectInteger(Format(wXpath, [_SHARD_ARIPOTLE_ID]));
    end;
  finally
    wResponse.Free;
  end;
end;

{*******************************************************************************
Sets the default filter for items
*******************************************************************************}
procedure TRyzom.SetDefaultFilter(var AFilter: TItemFilter);
begin
  AFilter.Enabled := True;
  AFilter.Type_ := [itAnimalMat, itNaturalMat, itCata, itEquipment, itOthers];
  AFilter.QualityMin := _MIN_QUALITY;
  AFilter.QualityMax := _MAX_QUALITY;
  AFilter.ClassMin := icBasic;
  AFilter.ClassMax := icSupreme;
  AFilter.Ecosystem := [ieCommon, iePrime, ieDesert, ieJungle, ieForest, ieLakes];
  AFilter.ItemName := '';
  AFilter.AllWords := True;
  AFilter.Equipment := [iqLightArmor, iqMediumArmor, iqHeavyArmor, iqWeaponMelee, iqWeaponRange, iqJewel, iqAmplifier, iqOthers];
  AFilter.CategoryIndex := 0;
end;

{*******************************************************************************
Returns information about an item from the item name
*******************************************************************************}
procedure TRyzom.GetItemInfoFromName(AItemInfo: TItemInfo);
var
  wIndex: Integer;
begin
  AItemInfo.ItemType := itOthers;
  AItemInfo.ItemEcosys := ieUnknown;
  AItemInfo.ItemSkin := isNoSkin;

  // Catalyzer
  if CompareText(AItemInfo.ItemName, _CATA_ITEM_NAME) = 0 then begin
    AItemInfo.ItemType := itCata;
    Exit;
  end;

  // Equipment
  GRegExpr.Expression := _EXPR_EQUIPMENT;
  if GRegExpr.Exec(AItemInfo.ItemName) then begin
    AItemInfo.ItemType := itEquipment;
    case Ord(GRegExpr.Match[1][1]) of
      116: AItemInfo.ItemEcosys := ieLakes; {t = tryker}
      102: AItemInfo.ItemEcosys := ieDesert; {f = fyros}
      109: AItemInfo.ItemEcosys := ieForest; {m = matis}
      122: AItemInfo.ItemEcosys := ieJungle; {z = zorai}
    else
      AItemInfo.ItemEcosys := ieCommon;
    end;

    AItemInfo.ItemSkin := isSkin1;
    case Ord(GRegExpr.Match[2][2]) of
      50: AItemInfo.ItemSkin := isSkin2; {2 = skin2}
      51: AItemInfo.ItemSkin := isSkin3; {3 = skin3}
    end;

    AItemInfo.ItemEquip := iqOthers;
    
    // Armor
    GRegExpr.Expression := _EXPR_EQUIPMENT_ARMOR;
    if GRegExpr.Exec(AItemInfo.ItemName) then begin
      case Ord(GRegExpr.Match[1][1]) of
        108: AItemInfo.ItemEquip := iqLightArmor; {l = light}
        99: AItemInfo.ItemEquip := iqLightArmor; {c = light}
        109: AItemInfo.ItemEquip := iqMediumArmor; {m = medium}
        104: AItemInfo.ItemEquip := iqHeavyArmor; {h = heavy}
      end;
    end;

    // Amplifier
    if AItemInfo.ItemEquip = iqOthers then begin
      GRegExpr.Expression := _EXPR_EQUIPMENT_AMPLIFIER;
      if GRegExpr.Exec(AItemInfo.ItemName) then begin
        AItemInfo.ItemEquip := iqAmplifier;
      end;
    end;

    // Weapon
    if AItemInfo.ItemEquip = iqOthers then begin
      GRegExpr.Expression := _EXPR_EQUIPMENT_WEAPON;
      if GRegExpr.Exec(AItemInfo.ItemName) then begin
        case Ord(GRegExpr.Match[1][1]) of
          109: AItemInfo.ItemEquip := iqWeaponMelee; {m = melee}
          114: AItemInfo.ItemEquip := iqWeaponRange; {r = range}
        end;
        case Ord(GRegExpr.Match[2][1]) of
          49: AItemInfo.ItemWeapon := iwOneHand; {1 = 1 hand}
          50: AItemInfo.ItemWeapon := iwTwoHands; {2 = 2 hands}
        end;
      end;
    end;

    // Jewel
    if AItemInfo.ItemEquip = iqOthers then begin
      GRegExpr.Expression := _EXPR_EQUIPMENT_JEWEL;
      if GRegExpr.Exec(AItemInfo.ItemName) then begin
        AItemInfo.ItemEquip := iqJewel;
      end;
    end;
  end;

  // Natural materials
  if AItemInfo.ItemType = itOthers then begin
    GRegExpr.Expression := _EXPR_NATURAL_MAT;
    if GRegExpr.Exec(AItemInfo.ItemName) then
      AItemInfo.ItemType := itNaturalMat;
  end;

  // Animal materials
  if AItemInfo.ItemType = itOthers then begin
    GRegExpr.Expression := _EXPR_ANIMAL_MAT;
    if GRegExpr.Exec(AItemInfo.ItemName) then
      AItemInfo.ItemType := itAnimalMat;
  end;

  // Natural and Animal
  if (AItemInfo.ItemType = itNaturalMat) or (AItemInfo.ItemType = itAnimalMat) then begin
    // Categories
    AItemInfo.ItemCategory1 := 'Unknown';
    AItemInfo.ItemCategory2 := 'Unknown';
    wIndex := FCatStrings.IndexOfName(Copy(AItemInfo.ItemName, 1, 5));
    if wIndex >= 0 then begin
      AItemInfo.ItemCategory1 := FCatStrings.ValueFromIndex[wIndex];
      AItemInfo.ItemCategory2 := FCatStrings.ValueFromIndex[wIndex+1];
    end;

    // Ecosystem
    case Ord(GRegExpr.Match[1][1]) of
      99: AItemInfo.ItemEcosys := ieCommon; {c}
      112: AItemInfo.ItemEcosys := iePrime; {p}
      100: AItemInfo.ItemEcosys := ieDesert; {d}
      102: AItemInfo.ItemEcosys := ieForest; {f}
      108: AItemInfo.ItemEcosys := ieLakes; {l}
      106: AItemInfo.ItemEcosys := ieJungle; {j}
    end;
  end;

  // Natural
  if AItemInfo.ItemType = itNaturalMat then begin
    case Ord(GRegExpr.Match[2][1]) of
      98: AItemInfo.ItemClass := icBasic; {b}
      99: AItemInfo.ItemClass := icFine; {c}
      100: AItemInfo.ItemClass := icChoice; {d}
      101: AItemInfo.ItemClass := icExcellent; {e}
      102: AItemInfo.ItemClass := icSupreme; {f}
    end;
  end;

  // Animal
  if AItemInfo.ItemType = itAnimalMat then begin
    case Ord(GRegExpr.Match[2][1]) of
      97: AItemInfo.ItemClass := icBasic; {a}
      98: AItemInfo.ItemClass := icFine; {b}
      99: AItemInfo.ItemClass := icChoice; {c}
      100: AItemInfo.ItemClass := icExcellent; {d}
      101: AItemInfo.ItemClass := icSupreme; {e}
    end;
  end;
end;

{*******************************************************************************
Verifies if the item respects the filter
*******************************************************************************}
function TRyzom.CheckItem(AItemInfo: TItemInfo; AFilter: TItemFilter): Boolean;
var
  wList: TStringList;
  wFound: Boolean;
  wCatIndex1: Integer;
  wCatIndex2: Integer;
  i: Integer;
begin
  Result := False;

  // If not type then Exit
  if AFilter.Type_ = [] then Exit;

  // Quality
  if (AItemInfo.ItemQuality < AFilter.QualityMin) or (AItemInfo.ItemQuality > AFilter.QualityMax) then Exit;

  // If the name does not match
  if AFilter.ItemName <> '' then begin
    wList := TStringList.Create;
    try
      wList.CommaText := MdkRemoveAccents(AFilter.ItemName);
      AItemInfo.ItemDesc := MdkRemoveAccents(AItemInfo.ItemDesc);
      wFound := AFilter.AllWords;
      i := 0;
      while (i < wList.Count) do begin
        if AFilter.AllWords then
          wFound := wFound and (Pos(UpperCase(wList[i]), UpperCase(AItemInfo.ItemDesc)) > 0)
        else
          wFound := wFound or (Pos(UpperCase(wList[i]), UpperCase(AItemInfo.ItemDesc)) > 0);
        Inc(i);
      end;
      if not wFound then Exit;
    finally
      wList.Free;
    end;
  end;

  // Type
  if not (AItemInfo.ItemType in AFilter.Type_) then Exit;

  // Materials and equipment
  if AItemInfo.ItemType in [itAnimalMat, itNaturalMat, itEquipment] then begin
    // Ecosystem
    if not (AItemInfo.ItemEcosys in AFilter.Ecosystem) then Exit;

    // Class
    if (Ord(AItemInfo.ItemClass) < Ord(AFilter.ClassMin)) or (Ord(AItemInfo.ItemClass) > Ord(AFilter.ClassMax)) then Exit;

  end;
  
  // Item category (only materials)
  if AItemInfo.ItemType in [itAnimalMat, itNaturalMat] then begin
    if (AFilter.CategoryIndex > 0) and (Pos('m0312', AItemInfo.ItemName) = 0) {larva} then begin
      wCatIndex1 := AnsiIndexText(AItemInfo.ItemCategory1, _ITEM_CATEGORY)+1;
      wCatIndex2 := AnsiIndexText(AItemInfo.ItemCategory2, _ITEM_CATEGORY)+1;
      if (wCatIndex1 <> AFilter.CategoryIndex) and (wCatIndex2 <> AFilter.CategoryIndex) then Exit;
    end;
  end;
  
  // Item equipment
  if AItemInfo.ItemType = itEquipment then begin
    if AFilter.Equipment = [] then Exit;
    if not (AItemInfo.ItemEquip in AFilter.Equipment) then Exit;
  end;

  Result := True;
end;

end.
