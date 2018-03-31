unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ComCtrls,
  StdCtrls, ExtCtrls, LazWebkitCtrls, RegExpr, Types;

type

  { TForm1 }

  TForm1 = class(TForm)
    btnGo: TButton;
    btnSave: TButton;
    btnGetContent: TButton;
    btnStartScrap: TButton;
    btnAddNewSource: TButton;
    codeOfRegex: TComboBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    listOfRegex: TListBox;
    Memo1: TMemo;
    Memo2: TMemo;
    urlOfSourceFirstPage: TEdit;
    listOfSources: TListBox;
    pathAutoSave: TEdit;
    isAutoSave: TCheckBox;
    listOfURLProxies: TComboBox;
    listOfProxies: TMemo;
    PageControl1: TPageControl;
    BrowserTab: TTabSheet;
    ProxiesTab: TTabSheet;
    SaveDialog1: TSaveDialog;
    browser: TWebkitBrowser;
    TabSheet1: TTabSheet;
    Timer1: TTimer;
    procedure browserLoaded(Sender: TObject);
    procedure BrowserTabContextPopup(Sender: TObject; MousePos: TPoint;
      var Handled: Boolean);
    procedure btnGoClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure btnGetContentClick(Sender: TObject);
    procedure btnStartScrapClick(Sender: TObject);
    procedure btnAddNewSourceClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure listOfRegexClick(Sender: TObject);
    procedure listOfSourcesClick(Sender: TObject);
    procedure listOfURLProxiesChange(Sender: TObject);
    procedure Memo1Change(Sender: TObject);
    procedure TabSheet1ContextPopup(Sender: TObject; MousePos: TPoint;
      var Handled: Boolean);
    procedure Timer1Timer(Sender: TObject);
  private
    { private declarations }
    procedure checkCurrentSiteRegex();
    function getCurrentSiteURL():String;
    function getShortSiteURLAddress():String;
  public
    { public declarations }
    regexExpressionForSite:string;
    currentPage:Integer;
    lastPage:Integer;
  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.btnGoClick(Sender: TObject);
var url:String;
begin
  browser.LoadURI(getCurrentSiteURL());
end;

procedure TForm1.browserLoaded(Sender: TObject);
begin
  //get all proxies on the page
  btnGetContent.Click;

  //check if it last page
  if(currentPage<lastPage) then begin
    //increase currentPage
    //and load next page
    currentPage:=currentPage+1;
    listOfProxies.Lines.Add('page number '+IntToStr(currentPage));
    browser.LoadURI(getCurrentSiteURL());
  end
  else begin
   //check if there are more pages in list of Sites With Proxies
   //and select NEXT site for get all proxies from all pages
   if(listOfURLProxies.ItemIndex<listOfURLProxies.Items.Count-1) then begin
     listOfURLProxies.ItemIndex:=listOfURLProxies.ItemIndex+1;
     currentPage:=1;
     //check current site
     //and setup regex expressions
     checkCurrentSiteRegex();
     listOfProxies.Lines.Add('NEXT SITE - listOfURLProxies.ItemIndex - page number '+IntToStr(currentPage)+
           ' listOfURLProxies.ItemIndex='+IntToStr(listOfURLProxies.ItemIndex)+
           ' getCurrentSiteURL()='+getCurrentSiteURL()
          );
     browser.LoadURI(getCurrentSiteURL());
   end
   else begin
      //ShowMessage('all proxies downloaded!');
      if(isAutoSave.Checked) then begin
         listOfProxies.Lines.SaveToFile(pathAutoSave.Text);
      end;
   end;
  end;
end;

procedure TForm1.BrowserTabContextPopup(Sender: TObject; MousePos: TPoint;
  var Handled: Boolean);
begin

end;

procedure TForm1.btnSaveClick(Sender: TObject);
begin
  if SaveDialog1.Execute then
    listOfProxies.Lines.SaveToFile( SaveDialog1.Filename );
 end;

procedure TForm1.btnGetContentClick(Sender: TObject);
var
  RegexObj: TRegExpr;
begin
  RegexObj := TRegExpr.Create;
//RegexObj.Expression := '.*login.*';
  RegexObj.Expression := regexExpressionForSite;
  //ShowMessage(IntToStr(listOfURLProxies.ItemIndex)+' - '+regexExpressionForSite);


  if RegexObj.Exec(browser.ExtractContent(TWebKitViewContentFormat.wvcfPlainText)) then
   repeat
        begin
         listOfProxies.Lines.Add('['+getShortSiteURLAddress()+'] '+RegexObj.Match[1]+':'+RegexObj.Match[2]);
        end
   until not RegexObj.ExecNext
   else
    begin
         listOfProxies.Lines.Add('proxy not found! - current regexExpressionForSite='+regexExpressionForSite);
    end;


  RegexObj.Free;
end;

procedure TForm1.btnStartScrapClick(Sender: TObject);
begin

  listOfProxies.Lines.Clear;
  listOfProxies.Lines.Add(DateTimeToStr(Now));

  ///first site and 10 pages
  listOfURLProxies.ItemIndex:=0;
  lastPage:=10;

  //check current site
  //and setup regex expressions
  checkCurrentSiteRegex();

  //setup current page
  //and load first page
  currentPage:=1;
  listOfProxies.Lines.Add('page number '+IntToStr(currentPage));
  browser.LoadURI(getCurrentSiteURL());
end;

procedure TForm1.btnAddNewSourceClick(Sender: TObject);
var i:Integer;
  isExist:Boolean;
begin
  isExist:=false;
  if((urlOfSourceFirstPage.Text<>'')AND(codeOfRegex.Text<>'')) then begin
    //check if this source already in a list
    for i:=0 to listOfSources.Items.Count-1 do begin
        if(listOfSources.Items[i]=urlOfSourceFirstPage.Text)then
         begin
             isExist:=true;
         end;
    end;
    if(isExist)then begin
      ShowMessage('this site already in the list, cancel');
    end
    else begin
      //add to list of sources
      listOfSources.Items.Add(urlOfSourceFirstPage.Text);
      //add to list of URL proxies
      listOfURLProxies.Items.Add(urlOfSourceFirstPage.Text);
      //add regex to list
      listOfRegex.Items.Add(codeOfRegex.Text);
      //save files with new values
      listOfSources.Items.SaveToFile('sources');
      listOfRegex.Items.SaveToFile('regex');
    end;
  end else begin
   ShowMessage('Please enter url and regex expression');
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  listOfSources.Items.LoadFromFile('sources');
  listOfURLProxies.Items.LoadFromFile('sources');
  listOfRegex.Items.LoadFromFile('regex');
  codeOfRegex.Items.Add('([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)\s+([0-9]+)');
  codeOfRegex.Items.Add('([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)\:([0-9]+)');
end;

procedure TForm1.listOfRegexClick(Sender: TObject);
begin
    listOfSources.ItemIndex:=listOfRegex.ItemIndex;
end;

procedure TForm1.listOfSourcesClick(Sender: TObject);
begin
  listOfRegex.ItemIndex:=listOfSources.ItemIndex;
end;

procedure TForm1.listOfURLProxiesChange(Sender: TObject);
begin
     checkCurrentSiteRegex();
end;

procedure TForm1.Memo1Change(Sender: TObject);
begin

end;

procedure TForm1.TabSheet1ContextPopup(Sender: TObject; MousePos: TPoint;
  var Handled: Boolean);
begin

end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
     btnStartScrap.Click;
end;

procedure TForm1.checkCurrentSiteRegex();
begin
 regexExpressionForSite:=listOfRegex.Items[listOfURLProxies.ItemIndex];
end;

function TForm1.getCurrentSiteURL():String;
begin
 Result:=stringReplace(listOfURLProxies.Items[listOfURLProxies.ItemIndex] , '[1]',  IntToStr(currentPage) ,[rfReplaceAll, rfIgnoreCase]);
end;

function TForm1.getShortSiteURLAddress():String;
var
  RegexObj: TRegExpr;
begin
  RegexObj := TRegExpr.Create;
  RegexObj.Expression := '(https?\://.*?/)';
  if RegexObj.Exec(listOfURLProxies.Items[listOfURLProxies.ItemIndex]) then
   begin
     Result:=RegexObj.Match[1];
   end;
end;

end.

