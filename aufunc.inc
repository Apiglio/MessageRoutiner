//aufscript function definition

procedure print_version(Sender:TObject);
var AufScpt:TAufScript;
begin
  AufScpt:=Sender as TAufScript;
  AufScpt.writeln('Apiglio Message Routiner');
  AufScpt.writeln('- version '+version_number+' -');
  AufScpt.writeln('- by Apiglio -');
end;

procedure getwind_name_visible(Sender:TObject);
var AAuf:TAuf;
    AufScpt:TAufScript;
    wind_name:string;
    tmp:TAufRamVar;
    hd:hwnd;
    info:tagWindowInfo;
    hidden:boolean=false;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  if not AAuf.TryArgToString(2,wind_name) then exit;
  if not AAuf.TryArgToARV(1,8,High(dword),[ARV_FixNum],tmp) then exit;
  hd:=FindWindow(nil,PChar(utf8towincp(wind_name)));
  while (hd<>0) and hidden do begin
    hidden:=false;
    GetWindowInfo(hd,info);
    if info.rcWindow.Width*info.rcWindow.Height=0 then hidden:=true;
    if (info.rcWindow.Left<-info.rcWindow.Width) or (info.rcWindow.Left>Desktop.Width) then hidden:=true;
    if (info.rcWindow.Top<-info.rcWindow.Height) or (info.rcWindow.Top>Desktop.Height) then hidden:=true;
  end;
  dword_to_arv(hd,tmp);

end;

procedure getwind_top(Sender:TObject);
var AAuf:TAuf;
    AufScpt:TAufScript;
    tmp,name_tmp:TAufRamVar;
    hd:hwnd;
    ntmp:array[0..255]of char;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(2) then exit;
  if not AAuf.TryArgToARV(1,4,High(dword),[ARV_FixNum],tmp) then exit;
  if AAuf.ArgsCount>2 then begin
    if not AAuf.TryArgToARV(2,4,High(dword),[ARV_FixNum],name_tmp) then exit;
  end else name_tmp.size:=0;
  hd:=GetForegroundWindow;
  dword_to_arv(hd,tmp);
  if name_tmp.size<>0 then begin
    GetWindowText(hd,ntmp,min(name_tmp.size,240));
    initiate_arv_str(wincptoutf8(ntmp),name_tmp);
  end;
end;

procedure getwind_size(Sender:TObject);
var AAuf:TAuf;
    AufScpt:TAufScript;
    wind_name:string;
    x,y,w,h:TAufRamVar;
    hd:longint;
    info:tagWindowInfo;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(6) then exit;
  if not AAuf.TryArgToLong(1,hd) then exit;
  if not AAuf.TryArgToARV(2,8,High(dword),[ARV_FixNum],x) then exit;
  if not AAuf.TryArgToARV(3,8,High(dword),[ARV_FixNum],y) then exit;
  if not AAuf.TryArgToARV(4,8,High(dword),[ARV_FixNum],w) then exit;
  if not AAuf.TryArgToARV(5,8,High(dword),[ARV_FixNum],h) then exit;
  if hd<>0 then begin
    GetWindowInfo(hd,info);
    dword_to_arv(info.rcWindow.Top,y);
    dword_to_arv(info.rcWindow.Left,x);
    dword_to_arv(info.rcWindow.Width,w);
    dword_to_arv(info.rcWindow.Height,h);
  end else begin
    dword_to_arv(0,x);
    dword_to_arv(0,y);
    dword_to_arv(Desktop.Width,w);
    dword_to_arv(Desktop.Height,h);
  end;
end;

procedure wndlist_update(Sender:TObject);
var AAuf:TAuf;
    AufScpt:TAufScript;
    filter_str,use_reg_str:string;
    use_reg:boolean=false;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(2) then exit;
  if not AAuf.TryArgToString(1,filter_str) then exit;
  if AAuf.ArgsCount>=3 then begin
    if not AAuf.TryArgToString(2,use_reg_str) then exit;
  end else use_reg_str:='';
  case lowercase(use_reg_str) of
    'on':use_reg:=true;
    else use_reg:=false;
  end;
  Form_Routiner.TreeView_Wnd.items.clear;
  WndFinder(filter_str,use_reg);
  //Form_Routiner.Memo_Tmp.Clear;
  //for use_reg_str in WndFlat do AufScpt.writeln(use_reg_str);
  WndTmp.Clear;//如果刷新列表之后再wndnew.pop，列表里的TWindow就会出错。
  Application.ProcessMessages;
end;

procedure wndlist_find(Sender:TObject);
var AAuf:TAuf;
    AufScpt:TAufScript;
    filter_str,use_reg_str:string;
    use_reg:boolean=false;
  function CheckWnd(WndName:string):boolean;
  begin
    try
       if use_reg then result:=Reg.Exec(WndName)
       else result:=pos(filter_str,WndName)>0;
    except
      result:=false;
    end;
  end;

begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(2) then exit;
  if not AAuf.TryArgToString(1,filter_str) then exit;
  if AAuf.ArgsCount>=3 then begin
    AAuf.TryArgToString(2,use_reg_str);
  end else use_reg_str:='';
  case lowercase(use_reg_str) of
    'on':use_reg:=true;
    else use_reg:=false;
  end;
  Reg.Expression:=filter_str;
  for use_reg_str in WndFlat do begin
    if CheckWnd(use_reg_str) then AufScpt.writeln(use_reg_str);
  end;
end;

procedure wndlist_new_init(Sender:TObject);//wndnew.init
var AAuf:TAuf;
    AufScpt:TAufScript;
    stmp:string;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  WndSub.Clear;
  for stmp in WndFlat do WndSub.Add(stmp);
end;

procedure wndlist_new_update(Sender:TObject);//wndnew.update filter,use_reg[,-show]
var AAuf:TAuf;
    AufScpt:TAufScript;
    filter_str,use_reg_str,show_list_str:string;
    use_reg:boolean;
    pi,useless:integer;
    show_list:boolean;
  function CheckWnd(WndName:string):boolean;
  begin
    try
      if use_reg then result:=Reg.Exec(WndName)
      else result:=pos(filter_str,WndName)>0;
    except
      result:=false;
    end;
  end;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(2) then exit;
  if not AAuf.TryArgToString(1,filter_str) then exit;
  if AAuf.ArgsCount>=3 then begin
    if not AAuf.TryArgToString(2,use_reg_str) then exit;
  end else use_reg_str:='';
  if AAuf.ArgsCount>=4 then begin
    if not AAuf.TryArgToStrParam(3,['-show','-list','-quiet'],false,show_list_str) then exit;
  end else show_list_str:='-quiet';
  show_list:=not(lowercase(show_list_str)='-quiet');
  case lowercase(use_reg_str) of
    'on':use_reg:=true;
    else use_reg:=false;
  end;
  WndTmp.Clear;
  for pi:=0 to WndFlat.Count-1 do begin
    WndTmp.Add(WndFlat[pi]);
    WndTmp.Objects[pi]:=WndFlat.Objects[pi];
  end;
  pi:=0;
  while pi<WndTmp.Count do begin
    if WndSub.Find(WndTmp[pi],useless) then
      WndTmp.Delete(pi)
    else begin
      if show_list then AufScpt.writeln(WndTmp[pi]);
      inc(pi);
    end;
  end;
end;

procedure wndlist_new_pop(Sender:TObject);//wndnew.pop @hwnd
var AAuf:TAuf;
    AufScpt:TAufScript;
    tmp:TAufRamVar;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(2) then exit;
  if not AAuf.TryArgToARV(1,8,High(Dword),[ARV_FixNum],tmp) then exit;
  if WndTmp.Count>0 then begin
    dword_to_arv(TWindow(WndTmp.Objects[0]).info.hd,tmp);
    WndTmp.Delete(0);
  end else begin
    dword_to_arv(0,tmp);
  end;
end;

procedure wndlist_new_empty(Sender:TObject);//wndnew.empty? :label
var AAuf:TAuf;
    AufScpt:TAufScript;
    line:pRam;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(2) then exit;
  if not AAuf.TryArgToAddr(1,line) then exit;
  if WndTmp.Count<=0 then begin
    AufScpt.jump_addr(line);
  end;
end;

procedure wnd_bring_to_top(Sender:TObject);//window.top hwnd
var AAuf:TAuf;
    AufScpt:TAufScript;
    hd:longint;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(2) then exit;
  if not AAuf.TryArgToLong(1,hd) then exit;
  BringWindowToTop(hd);
end;

procedure ui_message(Sender:TObject);//ui.message prompt
var AAuf:TAuf;
    AufScpt:TAufScript;
    prompt:string;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(2) then exit;
  if not AAuf.TryArgToString(1,prompt) then exit;
  ShowMessage(prompt);
end;

procedure ui_options(Sender:TObject);//ui.options @res,prompt,options[, ...]
var AAuf:TAuf;
    AufScpt:TAufScript;
    arv:TAufRamVar;
    index:integer;
    prompt,stmp:string;
    options:TStringList;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(4) then exit;
  if not AAuf.TryArgToARV(1,1,High(DWORD),[ARV_Char],arv) then exit;
  if not AAuf.TryArgToString(2,prompt) then exit;
  options:=TStringList.Create;
  try
    for index:=3 to AAuf.ArgsCount-1 do begin
      if not AAuf.TryArgToString(index,stmp) then exit;
      options.Add(stmp);
    end;
    with TMROptionForm.Create(nil,'MessageRoutiner',prompt) do try
      stmp:=Execute(options);
      initiate_arv_str(stmp,arv);
    finally
      Free;
    end;
  finally
    options.Free;
  end;
  //ShowMessage(prompt);
end;

procedure ui_set_sync_arv(Sender:TObject);//ui.setsync index,hwnd[,name]
var AAuf:TAuf;
    AufScpt:TAufScript;
    index:byte;
    arv_hwnd:longint;
    arv_name,old_name:string;
    window_name:array[0..239] of char;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  if not AAuf.TryArgToByte(1,index) then exit;
  if not AAuf.TryArgToLong(2,arv_hwnd) then exit;
  if AAuf.ArgsCount>3 then begin
    if not AAuf.TryArgToString(3,arv_name) then exit;
  end else begin
    arv_name:='';
  end;
  if index>SynCount then begin
    AufScpt.send_error('第1个参数index应为0至'+IntToStr(SynCount)+'的整数。');
    exit;
  end;
  GetWindowText(arv_hwnd,window_name,240);
  old_name:='@'+Form_Routiner.Buttons[index].expression;
  if arv_name='' then arv_name:=old_name;
  if Form_Routiner.Buttons[index].SetARV(old_name,arv_hwnd,WinCPToUTF8(window_name)) then begin
    if old_name<>arv_name then Form_Routiner.Edits[index].Caption:=arv_name;
  end else begin
    AufScpt.send_error(Form_Routiner.Buttons[index].EOptionSettingError);
  end;
end;

procedure SendString(Sender:TObject);
var hd:longint;
    str:string;
    i:integer;
    AAuf:TAuf;
    AufScpt:TAufScript;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  if not AAuf.TryArgToLong(1,hd) then exit;
  if not AAuf.TryArgToString(2,str) then exit;
  str:=utf8towincp(str);
  for i:=1 to length(str) do sendmessage(hd,WM_CHAR,ord(str[i]),0);
end;

procedure ClipBoardString(Sender:TObject);
var str:string;
    AAuf:TAuf;
    AufScpt:TAufScript;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(2) then exit;
  if not AAuf.TryArgToString(1,str) then exit;
  Clipboard.AsText:=str;
end;

procedure SendM(Sender:TObject);
var hd,msg,wparam,lparam:longint;
    AAuf:TAuf;
    AufScpt:TAufScript;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(5) then exit;
  if not AAuf.TryArgToLong(1,hd) then exit;
  if not AAuf.TryArgToLong(2,msg) then exit;
  case AAuf.nargs[3].pre of
    '"':wparam:=ord(AAuf.nargs[3].arg[1]);
    else if not AAuf.TryArgToLong(3,wparam) then exit;
  end;
  case AAuf.nargs[3].pre of
    '"':lparam:=ord(AAuf.nargs[4].arg[1]);
    else if not AAuf.TryArgToLong(4,lparam) then exit;
  end;
  SendMessage(hd,msg,wparam,lparam);
end;

procedure PostM(Sender:TObject);
var hd,msg,wparam,lparam:longint;
    AAuf:TAuf;
    AufScpt:TAufScript;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(5) then exit;
  if not AAuf.TryArgToLong(1,hd) then exit;
  if not AAuf.TryArgToLong(2,msg) then exit;
  case AAuf.nargs[3].pre of
    '"':wparam:=ord(AAuf.nargs[3].arg[1]);
    else if not AAuf.TryArgToLong(3,wparam) then exit;
  end;
  case AAuf.nargs[3].pre of
    '"':lparam:=ord(AAuf.nargs[4].arg[1]);
    else if not AAuf.TryArgToLong(4,lparam) then exit;
  end;
  PostMessage(hd,msg,wparam,lparam);
end;

procedure _Keybd(Sender:TObject);//keybd @w,"D/U",key
var hd,msg,wparam,lparam:longint;
    key:byte;
    str:string;
    AAuf:TAuf;
    AufScpt:TAufScript;
    buttonmode:string;
    alt_offset:byte;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(4) then exit;
  if not AAuf.TryArgToLong(1,hd) then exit;
  if not AAuf.TryArgToStrParam(2,['d','u'],false,buttonmode) then exit;
  case AAuf.nargs[3].pre of
    '"':begin
          if not AAuf.TryArgToString(3,str) then exit;
          if length(str) <> 1 then begin
            AufScpt.send_error('警告：指令第3参数不是字符或数字，代码未执行！');
            exit;
          end;
          key:=form_adapter.SynToKey(str[1]);
        end;
    else if not AAuf.TryArgToByte(3,key) then exit;
  end;

  if key in [18,164,165] then alt_offset:=4
  else alt_offset:=0;
  case buttonmode of
    'd','D':msg:=WM_KeyDown+alt_offset;
    'u','U':msg:=WM_KeyUp+alt_offset;
  end;
  wparam:=key;
  lparam:=(key shl 16) + 1;
  SendMessage(hd,msg,wparam,lparam);
end;

procedure _KeyPress(Sender:TObject);
var hd,key,delay:longint;
    AAuf:TAuf;
    AufScpt:TAufScript;
    alt_offset:byte;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(4) then exit;
  if not AAuf.TryArgToLong(1,hd) then exit;
  case AAuf.nargs[2].pre of
    '"':key:=ord(AAuf.nargs[2].arg[1]);
    else if not AAuf.TryArgToLong(2,key) then exit;
  end;
  if key in [18,164,165] then alt_offset:=4
  else alt_offset:=0;
  if not AAuf.TryArgToLong(3,delay) then exit;
  if delay=0 then delay:=50;
  PostMessage(hd,WM_KeyDown+alt_offset,key,{(key shl 32)+}1);
  process_sleep(delay);
  PostMessage(hd,WM_KeyUp+alt_offset,key,{(key shl 32)+}1);

end;

procedure _Mouse(Sender:TObject);//mouse @w,"L/M/R"+"D/U/B",x,y
var hd,msg,wparam,lparam:longint;
    x,y:dword;
    AAuf:TAuf;
    AufScpt:TAufScript;
    buttonmode:string;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(5) then exit;
  if not AAuf.TryArgToLong(1,hd) then exit;
  if not AAuf.TryArgToStrParam(2,['ld','md','rd','lu','mu','ru','lb','mb','rb'],false,buttonmode) then exit;
  if not AAuf.TryArgToDWord(3,x) then exit;
  if not AAuf.TryArgToDWord(4,y) then exit;
  case lowercase(buttonmode) of
    'ld':msg:=WM_LButtonDown;
    'md':msg:=WM_MButtonDown;
    'rd':msg:=WM_RButtonDown;
    'lu':msg:=WM_LButtonUp;
    'mu':msg:=WM_MButtonUp;
    'ru':msg:=WM_RButtonUp;
    'lb':msg:=WM_LBUTTONDBLCLK;
    'mb':msg:=WM_MBUTTONDBLCLK;
    'rb':msg:=WM_RBUTTONDBLCLK;
  end;
  wparam:=0;
  lparam:=(y shl 16) + x;
  SendMessage(hd,msg,wparam,lparam);
end;

procedure _MouseClk(Sender:TObject);//mouseclk @w,"L/M/R",x,y,delay
var hd,msg,wparam,lparam:longint;
    x,y,delay:dword;
    AAuf:TAuf;
    AufScpt:TAufScript;
    buttonmode:string;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(6) then exit;
  if not AAuf.TryArgToLong(1,hd) then exit;
  if not AAuf.TryArgToStrParam(2,['l','m','r'],false,buttonmode) then exit;
  if not AAuf.TryArgToDWord(3,x) then exit;
  if not AAuf.TryArgToDWord(4,y) then exit;
  if not AAuf.TryArgToDWord(5,delay) then exit;
  if delay=0 then delay:=50;
  case lowercase(buttonmode) of
    'l':msg:=WM_LButtonDown;
    'm':msg:=WM_MButtonDown;
    'r':msg:=WM_RButtonDown;
  end;
  wparam:=0;
  lparam:=(y shl 16) + x;
  SendMessage(hd,msg,wparam,lparam);
  process_sleep(delay);
  SendMessage(hd,msg+1,wparam,lparam);

end;

procedure _MouseMov(Sender:TObject);//mousemove @w,"LRCSM12",x,y
var hd,msg,wparam,lparam:longint;
    x,y:dword;
    AAuf:TAuf;
    AufScpt:TAufScript;
    buttonmode:string;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(5) then exit;
  if not AAuf.TryArgToLong(1,hd) then exit;
  if not AAuf.TryArgToString(2,buttonmode) then exit;
  if not AAuf.TryArgToDWord(3,x) then exit;
  if not AAuf.TryArgToDWord(4,y) then exit;
  buttonmode:=lowercase(buttonmode);
  wparam:=0;
  msg:=WM_MOUSEMOVE;
  if pos('l',buttonmode)>0 then wparam:=wparam or $01;
  if pos('r',buttonmode)>0 then wparam:=wparam or $02;
  if pos('s',buttonmode)>0 then wparam:=wparam or $04;
  if pos('c',buttonmode)>0 then wparam:=wparam or $08;
  if pos('m',buttonmode)>0 then wparam:=wparam or $10;
  if pos('1',buttonmode)>0 then wparam:=wparam or $20;
  if pos('2',buttonmode)>0 then wparam:=wparam or $40;
  lparam:=(y shl 16) + x;
  SendMessage(hd,msg,wparam,lparam);
end;

procedure _MouseWheel(Sender:TObject);//mousewheel @w,wheel_delta,"LRCSM12",x,y
var hd,msg,wparam,lparam,wheeldelta:longint;
    x,y:dword;
    AAuf:TAuf;
    AufScpt:TAufScript;
    buttonmode:string;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(6) then exit;
  if not AAuf.TryArgToLong(1,hd) then exit;
  if not AAuf.TryArgToLong(2,wheeldelta) then exit;
  if not AAuf.TryArgToString(3,buttonmode) then exit;
  if not AAuf.TryArgToDWord(4,x) then exit;
  if not AAuf.TryArgToDWord(5,y) then exit;
  buttonmode:=lowercase(buttonmode);
  wparam:=0;
  msg:=WM_MOUSEWHEEL;
  if pos('l',buttonmode)>0 then wparam:=wparam or $01;
  if pos('r',buttonmode)>0 then wparam:=wparam or $02;
  if pos('s',buttonmode)>0 then wparam:=wparam or $04;
  if pos('c',buttonmode)>0 then wparam:=wparam or $08;
  if pos('m',buttonmode)>0 then wparam:=wparam or $10;
  if pos('1',buttonmode)>0 then wparam:=wparam or $20;
  if pos('2',buttonmode)>0 then wparam:=wparam or $40;
  wparam:=(wheeldelta mod 65536) shl 16 + wparam;
  lparam:=(y shl 16) + x;
  SendMessage(hd,msg,wparam,lparam);
end;

function FunningColorExchange(ori:dword):dword;//  ABCD -> CBAD
var arr:array[0..3]of byte;
    tmp:byte;
    ptr:pbyte;
begin
  ptr:=@arr;
  pdword(ptr)^:=ori;
  tmp:=arr[2];
  arr[2]:=arr[0];
  arr[0]:=tmp;
  result:=pdword(ptr)^;
end;

procedure _GetPixel(Sender:TObject);//getpixel hwnd,col,row,@var
var hd:longint;
    x,y,res:dword;
    tmp:TAufRamVar;
    AAuf:TAuf;
    AufScpt:TAufScript;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(5) then exit;
  if not AAuf.TryArgToLong(1,hd) then exit;
  if hd=0 then begin AufScpt.send_error('警告：窗体句柄无效，代码未执行！');exit end;
  hd:=GetDC(hd);
  if hd=0 then begin AufScpt.send_error('警告：窗体句柄无对应HDC，代码未执行！');exit end;
  if not AAuf.TryArgToDWord(2,x) then exit;
  if not AAuf.TryArgToDWord(3,y) then exit;
  if not AAuf.TryArgToARV(4,4,High(dword),[ARV_FixNum],tmp) then exit;
  res:=FunningColorExchange(GetPixel(hd,x,y));
  dword_to_arv(res,tmp);
end;

procedure _GetPixelRect(Sender:TObject);//getrect hwnd,x1,x2,y1,y2,@var
var hd:longint;
    x1,x2,y1,y2,x,y,px,py:dword;
    img_size:dword;
    tmp:TAufRamVar;
    AAuf:TAuf;
    AufScpt:TAufScript;
    BDBitmapData:TBDBitmapData;
    tp,mp:dword;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(7) then exit;
  if not AAuf.TryArgToLong(1,hd) then exit;
  if hd=0 then begin     AufScpt.send_error('警告：窗体句柄无效，代码未执行！');exit end;
  if not AAuf.TryArgToDWord(2,x1) then exit;
  if not AAuf.TryArgToDWord(3,x2) then exit;
  if not AAuf.TryArgToDWord(4,y1) then exit;
  if not AAuf.TryArgToDWord(5,y2) then exit;
  if (x2<x1) or (y2<y1) then begin AufScpt.send_error('警告：未选中任何一个像素，代码未执行！');exit end;
  img_size:=(x2-x1+1)*(y2-y1+1);
  if not AAuf.TryArgToARV(6,img_size*4,img_size*4,[ARV_FixNum],tmp) then exit;
  BDBitmapData:=TBDBitmapData.Create;
  try
    BDBitmapData.CopyFormScreen(hd,x1,y1,x2-x1+1,y2-y1+1);
    px:=BDBitmapData.Width;
    py:=BDBitmapData.Height;
    for y:=y1 to y2 do
      for x:=x1 to x2 do begin
        tp:=4*((x2-x1+1)*(y-y1)+(x-x1));
        mp:=3*(px*(py-(y-y1)-1)+(x-x1));
        pbyte(tmp.Head+tp)^:=(pbyte(BDBitmapData.Bits+mp))^;
        pbyte(tmp.Head+tp+1)^:=(pbyte(BDBitmapData.Bits+mp+1))^;
        pbyte(tmp.Head+tp+2)^:=(pbyte(BDBitmapData.Bits+mp+2))^;
        pbyte(tmp.Head+tp+3)^:=$ff;
      end;
  finally
    BDBitmapData.Free;
  end;
end;

procedure _RamImage(Sender:TObject);//ramimg col,row,@var
var x,y:dword;
    pos,pot:longint;
    dit:pbyte;
    tmp:TAufRamVar;
    AAuf:TAuf;
    AufScpt:TAufScript;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(4) then exit;
  if not AAuf.TryArgToDWord(1,x) then exit;
  if not AAuf.TryArgToDWord(2,y) then exit;
  if not AAuf.TryArgToARV(3,x*y*4,x*y*4,[ARV_FixNum,ARV_Float,ARV_Char],tmp) then exit;
  Form_Routiner.Image_Ram.Picture.Free;
  Form_Routiner.Image_Ram.Picture:=TPicture.Create;
  Form_Routiner.Image_Ram.Picture.BitMap.PixelFormat:=pf32bit;
  Form_Routiner.Image_Ram.Picture.Bitmap.SetSize(x,y);
  CopyMemory(Form_Routiner.Image_Ram.Picture.Bitmap.ScanLine[0],tmp.Head,tmp.size);

  Form_Routiner.Image_Ram.Picture.Bitmap.SaveToFile('ram.bmp');
  Form_Routiner.Image_Ram.Refresh;
  Form_Routiner.ScrollBox_SynchronicResize(Form_Routiner.ScrollBox_Synchronic);
  Form_Routiner.ScrollBox_RecOptionResize(Form_Routiner.ScrollBox_RecOption);

end;


procedure _ARI_GetRect(Sender:TObject);//ari.get hwnd,@img[,x,y,w,h]
var hd:longint;
    info:tagWINDOWINFO;
    mem:TMemoryStream;
    dpiScaling:double;
    xx,yy,ww,hh:dword;
    tmp:TAufRamVar;
    AAuf:TAuf;
    AufScpt:TAufScript;
    BDBitmapData:TBDBitmapData;
    procedure GetWindowRect;
    begin
      xx:=0;
      yy:=0;
      GetWindowInfo(hd,info);
      ww:=round(info.rcWindow.Width*dpiScaling);
      hh:=round(info.rcWindow.Height*dpiScaling);
    end;

begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  if not AAuf.TryArgToLong(1,hd) then exit;
  if hd=0 then begin AufScpt.send_error('警告：窗体句柄无效，代码未执行！');exit end;
  if not AAuf.TryArgToARV(2,8,8,[ARV_FixNum],tmp) then exit;
  dpiScaling:=GetDPIScaling;
  if AAuf.ArgsCount>3 then begin
    if not AAuf.TryArgToDWord(3,xx) then exit;
    if not AAuf.TryArgToDWord(4,yy) then exit;
    if not AAuf.TryArgToDWord(5,ww) then exit;
    if not AAuf.TryArgToDWord(6,hh) then exit;
    xx:=round(xx*dpiScaling);
    yy:=round(yy*dpiScaling);
    ww:=round(ww*dpiScaling);
    hh:=round(hh*dpiScaling);
    if ww*hh=0 then GetWindowRect;
  end else GetWindowRect;

  BDBitmapData:=TBDBitmapData.Create;
  mem:=TMemoryStream.Create;
  try
    BDBitmapData.CopyFormScreen(hd,xx,yy,ww,hh);
    BDBitmapData.SaveToStream(mem);
    mem.Position:=0;
    (arv_to_obj(tmp) as TARImage).LoadFromStream(mem);
  finally
    BDBitmapData.Free;
    mem.Free;
  end;
end;

procedure _ARI_Display(Sender:TObject);//ari.dsp @img -u/-d
var ww,hh:word;
    itmp:TObject;
    AAuf:TAuf;
    AufScpt:TAufScript;
    mode:string;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(2) then exit;
  if not AAuf.TryArgToObject(1,TARImage,itmp) then exit;
  with itmp as TARImage do begin
    ww:=Width;
    hh:=Height;
  end;
  if hh*ww=0 then begin
    AufScpt.send_error('ARI图像为空图。');
    exit;
  end;

  if AAuf.ArgsCount>2 then begin
    if not AAuf.TryArgToStrParam(2,['-d','-u'],false,mode) then exit;
  end else mode:='-u';

  Form_Routiner.Image_Ram.Picture.Free;
  Form_Routiner.Image_Ram.Picture:=TPicture.Create;
  Form_Routiner.Image_Ram.Picture.BitMap.PixelFormat:=pf32bit;
  Form_Routiner.Image_Ram.Picture.Bitmap.SetSize(ww,hh);
  Form_Routiner.Image_Ram.Picture.Bitmap.Assign((itmp as TARImage).FPicture.Bitmap);
  Form_Routiner.Image_Ram.Refresh;
  case lowercase(mode) of
    '-d':with Form_Routiner.ScrollBox_ImageViewScroll.VertScrollBar do Position:=Range-1;
    else ;
  end;
  Form_Routiner.ScrollBox_SynchronicResize(Form_Routiner.ScrollBox_Synchronic);
  Form_Routiner.ScrollBox_RecOptionResize(Form_Routiner.ScrollBox_RecOption);

end;

procedure PushCursor(Sender:TObject);//pushcursor x,y[,window]
var AAuf:TAuf;
    AufScpt:TAufScript;
    pos_x,pos_y,hd:longint;
    tmpPoint:TPoint;
    info:TWindowInfo;
    dpi:double;
begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.CheckArgs(3) then exit;
  if not AAuf.TryArgToLong(1,pos_x) then exit;
  if not AAuf.TryArgToLong(2,pos_y) then exit;
  if AAuf.ArgsCount>=4 then begin
    if not AAuf.TryArgToLong(3,hd) then exit;
  end else begin
    hd:=0;
  end;
  if hd<>0 then begin
    GetWindowInfo(hd,info);
    inc(pos_y,info.rcWindow.Top);
    inc(pos_x,info.rcWindow.Left);
  end;
  dpi:=GetDPIScaling;
  pos_x:=trunc(pos_x/dpi);
  pos_y:=trunc(pos_y/dpi);
  if not GetCursorPos(tmpPoint) then begin AufScpt.send_error('读取鼠标坐标失败。');exit end;
  Form_Routiner.PushMouseCursor(tmpPoint);
  SetCursorPos(pos_x,pos_y);
end;

procedure PopCursor(Sender:TObject);//popcursor
var tmpPoint:TPoint;
begin
  tmpPoint:=Form_Routiner.PopMouseCursor();
  SetCursorPos(tmpPoint.X,tmpPoint.Y);
end;

operator in(elem:string; arr:array of string):boolean;
var idx:integer;
begin
  result:=true;
  idx:=Length(arr)-1;
  while idx>=0 do begin
    if arr[idx]=elem then exit;
    dec(idx);
  end;
  result:=false;
end;

procedure Routiner_Setting(Sender:TObject);
const _bool_values_:array[0..9] of string = ('true','false','t','f','on','off','yes','no','y','n');
      _true_values_:array[0..4] of string = ('true','t','on','yes','y');
var AufScpt:TAufScript;
    AAuf:TAuf;
    fo,ww,hh,tt,ll:longint;
    s1,s2:string;
    slst:TStringList;
    pf:TForm;
    branch,option,value,err_res:string;

begin
  AufScpt:=Sender as TAufScript;
  AAuf:=AufScpt.Auf as TAuf;
  if not AAuf.TryArgToStrParam(1,
  ['title','version','axis','form','layout','customer_layout','aufbutton',
  'holdbutton','action_setting','wndlist','shortcut','shortcut_command','boolean_options'],
  false,branch) then exit;
  case lowercase(branch) of
    'title':{伪指令};
    'version':{伪指令};
    'axis':
      begin
        if not AAuf.CheckArgs(4) then exit;
        if not AAuf.TryArgToLong(3,{tmp}ww) then exit;
        if not AAuf.TryArgToStrParam(2,['mainv=','syncv=','buttonv=','lefth=','righth=','rech=','codev='],false,option) then exit;
        try
          case lowercase(option) of
            'mainv=':Form_Routiner.Splitter_MainV.Left:={tmp}ww;
            'syncv=':Form_Routiner.Splitter_SyncV.Left:={tmp}ww;
            'buttonv=':Form_Routiner.Splitter_ButtonV.Left:={tmp}ww;
            'lefth=':Form_Routiner.Splitter_LeftH.Top:={tmp}ww;
            'righth=':Form_Routiner.Splitter_RightH.Top:={tmp}ww;
            'rech=':Form_Routiner.Splitter_RecH.Top:={tmp}ww;
            'codev=':
              begin
                if AAuf.ArgsCount>=5 then AAuf.TryArgToLong(4,fo) else fo:=-1;
                if (fo<0) or (fo>RuleCount) then fo:=Form_Routiner.PageControl.PageIndex;
                with Form_Routiner.AufScriptFrames[fo].Frame do
                  Splitter_Vert.Left:={tmp}ww * Width div 100;
              end;
          end;
        except
          AufScpt.send_error('参数错误，未成功设置！')
        end;
      end;
    'form':
      begin
        if not AAuf.CheckArgs(7) then exit;
        if not AAuf.TryArgToLong(2,fo) then exit;
        if not AAuf.TryArgToLong(3,tt) then exit;
        if not AAuf.TryArgToLong(4,ll) then exit;
        if not AAuf.TryArgToLong(5,ww) then exit;
        if not AAuf.TryArgToLong(6,hh) then exit;
        case fo of
          1:pf:=Form_Routiner;
          2:pf:=AufButtonForm;
          3:pf:=SettingLagForm;
          4:pf:=ManualForm;
          5:pf:=FormRunPerformance;
          6:pf:=FormHoldButtonSetting;
          else begin AufScpt.send_error('未找到指定窗口，未设置成功。');exit end;
        end;
        with pf do begin
          Top:=tt;
          Left:=ll;
          Width:=ww;
          Height:=hh;
        end;
      end;
    'layout':
      begin
        if not AAuf.CheckArgs(3) then exit;
        if not AAuf.TryArgToLong(2,fo) then exit;
        Form_Routiner.Layout.LayoutCode:=TLayoutSet(fo);
        Form_Routiner.SetLayout(byte(Form_Routiner.Layout.LayoutCode));
        Form_Routiner.FormResize(Form_Routiner);
      end;
    'customer_layout':
      begin
        if not AAuf.CheckArgs(10) then exit;
        with Form_Routiner.Layout.customer_layout do begin
          AAuf.TryArgToLong(2,Width);
          AAuf.TryArgToLong(3,Height);
          AAuf.TryArgToLong(4,MainV);
          AAuf.TryArgToLong(5,SyncV);
          AAuf.TryArgToLong(6,ButtV);
          AAuf.TryArgToLong(7,LeftH);
          AAuf.TryArgToLong(8,RightH);
          AAuf.TryArgToLong(9,RecH);
        end;
      end;
    'aufbutton':
      begin
        if not AAuf.CheckArgs(7) then exit;
        err_res:='';
        if not AAuf.TryArgToLong(2,{winID}ww) then exit;
        if not AAuf.TryArgToLong(3,{colID}hh) then exit;
        if not AAuf.TryArgToString(4,{caption}option) then exit;
        if not AAuf.TryArgToLong(5,{winIndex}ll) then exit;
        if not AAuf.TryArgToString(6,{path}value) then exit;
        if (ww>SynCount) or (ww<0) then err_res:='syncount';
        if (ll>SynCount) or (ll<0) then err_res:='syncount';
        if (hh>ButtonColumn) or (hh<0) then err_res:='buttoncolumn';
        if err_res<>'' then begin
          AufScpt.send_error('参数存在错误，未完成设置！');
          exit;
        end;
        Form_Routiner.AufButtons[ww,hh].Caption:={caption}option;
        Form_Routiner.AufButtons[ww,hh].ScriptFile.CommaText:={path}value;
        Form_Routiner.AufButtons[ww,hh].WindowIndex:=ll;
      end;
    'holdbutton':
      begin
        if not AAuf.CheckArgs(8) then exit;
        err_res:='';
        if not AAuf.TryArgToLong(2,{ID}fo) then exit;
        if not AAuf.TryArgToString(3,{caption}option) then exit;
        if not AAuf.TryArgToLong(4,{key1}tt) then exit;
        if not AAuf.TryArgToLong(5,{key2}ll) then exit;
        if not AAuf.TryArgToLong(6,{key3}ww) then exit;
        if not AAuf.TryArgToLong(7,{last}hh) then exit;
        if (fo>31) or (fo<0) then err_res:='idx';
        if (tt>255) or (tt<0) then err_res:='top';
        if (ll>255) or (ll<0) then err_res:='left';
        if (ww>255) or (ww<0) then err_res:='width';
        if (hh>255) or (hh<0) then err_res:='bottom';
        if err_res<>'' then begin
          AufScpt.send_error('参数存在错误，未完成设置！');
          exit;
        end;
        with Form_Routiner.HoldButtons[fo] do begin
          Caption:={caption}option;
          keymessage[0]:=tt;
          keymessage[1]:=ll;
          keymessage[2]:=ww;
          keymessage[3]:=hh;
        end;
      end;
    'action_setting':
      begin
        if not AAuf.CheckArgs(4) then exit;
        if not AAuf.TryArgToString(3,value) then exit;
        if not AAuf.TryArgToStrParam(2,['ab_act=','ab_adv=','ab_halt=','ab_opt=','hb_opt='],false,option) then exit;
        with Form_Routiner.Setting do try
          case lowercase(option) of
            'ab_act=':  MouseActCodeToMouseActSetting(value, AufButton.Act1,       AufButton.Act2);
            'ab_adv=':  MouseActCodeToMouseActSetting(value, AufButton.ExtraAct1,  AufButton.ExtraAct2);
            'ab_halt=': MouseActCodeToMouseActSetting(value, AufButton.Halt1,      AufButton.Halt2);
            'ab_opt=':  MouseActCodeToMouseActSetting(value, AufButton.Setting1,   AufButton.Setting2);
            'hb_opt=':  MouseActCodeToMouseActSetting(value, HoldButton.Setting1,  HoldButton.Setting2);
          end;
        except
          AufScpt.send_error('参数只能包含LMR12CSA几个字符，未完成设置！');exit
        end;
      end;
    'wndlist':
      begin
        if not AAuf.CheckArgs(4) then exit;
        if not AAuf.TryArgToStrParam(2,['pos=','hwnd=','name=','class=','namecell=','aligncell='],false,option) then exit;
        case option of
          'namecell=','aligncell=':if not AAuf.TryArgToLong(3,{cell}fo) then exit;
          else if not AAuf.TryArgToStrParam(3,_bool_values_,false,value) then exit;
        end;
        try
          with Form_Routiner.Setting.WndListShowingOption do begin
            case lowercase(option) of
              'pos=':       PositionVisible  := lowercase(value) in _true_values_;
              'hwnd=':      HwndVisible      := lowercase(value) in _true_values_;
              'name=':      WndNameVisible   := lowercase(value) in _true_values_;
              'class=':     ClassNameVisible := lowercase(value) in _true_values_;
              'namecell=':  NameCell         :={cell}fo mod 256;
              'aligncell=': AlignCell        :={cell}fo mod 256;
            end;
          end;
        except
          AufScpt.send_error('参数只能包含LMR12CSA几个字符，未完成设置！');exit
        end;
      end;
    'shortcut':
      begin
        if not AAuf.CheckArgs(4) then exit;
        if not AAuf.TryArgToLong(3,fo) then exit;
        if not AAuf.TryArgToStrParam(2,['mode=','startkey=','endkey=','downupkey='],false,option) then exit;
        err_res:='';
        case lowercase(option) of
          'mode=':
            if (fo<0) or (fo>3) then err_res:='无效模式'
            else AdapterForm.Option.Shortcut.Mode:=TShortcutMode(fo);
          'startkey=':
            if (fo<0) or (fo>255) then err_res:='无效键盘值'
            else AdapterForm.Option.Shortcut.StartKey:=fo;
          'endkey=':
            if (fo<0) or (fo>255) then err_res:='无效键盘值'
            else AdapterForm.Option.Shortcut.EndKey:=fo;
          'downupkey=':
            if (fo<0) or (fo>255) then err_res:='无效键盘值'
            else AdapterForm.Option.Shortcut.DownUpKey:=fo;
        end;
        if err_res<>'' then AufScpt.send_error(err_res);
      end;
    'shortcut_command':
      begin
        if not AAuf.CheckArgs(5) then exit;
        if not AAuf.TryArgToLong(2,fo) then exit;
        if (fo<0) or (fo>ShortcutCount) then begin
          AufScpt.send_error('第2个参数需要在0-'+IntToStr(ShortcutCount)+'范围内，未成功设置！');
          exit;
        end;
        if not AAuf.TryArgToString(3,s1) then exit;
        if not AAuf.TryArgToString(4,s2) then exit;
        s2:=StringReplace(s2,'%Q','"',[rfReplaceAll]);
        if (s1<>'') and (s2<>'') then begin
          slst:=TStringList.Create;
          slst.Add(s2);
          AdapterForm.Option.Shortcut.CommandList.AddObject(s1,TObject(slst));
        end;
      end;
    'boolean_options':
      begin
        if not AAuf.CheckArgs(4) then exit;
        if not AAuf.TryArgToStrParam(2,['alwaysontop'],false,option) then exit;
        if not AAuf.TryArgToStrParam(3,['true','false','t','f'],false,value) then exit;
        case value of
          'true','t':Form_Routiner.AlwaysOnTopEnable
          else Form_Routiner.AlwaysOnTopDisable;
        end;
      end;
    //
    else AufScpt.send_error('未知的命令行设置项，未成功设置！');
  end;
end;

procedure CostumerFuncInitialize(AAuf:TAuf);
begin
  AAuf.Script.add_func('about,软件信息',@print_version,'','版本信息');
  AAuf.Script.add_func('string,发送字符串',@SendString,'hwnd,str','向窗口输入字符串');
  AAuf.Script.add_func('clipbd,修改剪贴板',@ClipBoardString,'str','向窗口输入字符串');
  AAuf.Script.add_func('keybd,键盘动作',@_KeyBd,'hwnd,"U/D",key|"char"','向hwnd窗口发送一个键盘消息');
  AAuf.Script.add_func('mouse,鼠标动作',@_Mouse,'hwnd,"L/M/R"+"U/D/B",x,y','向hwnd窗口发送一个鼠标消息');
  AAuf.Script.add_func('keypress,键盘按键',@_KeyPress,'hwnd,key|"char",deley','向hwnd窗口发送一对间隔delay毫秒的按键消息');
  AAuf.Script.add_func('mouseclk,鼠标按键',@_MouseClk,'hwnd,"L/M/R",x,y,delay','向hwnd窗口发送一对间隔delay毫秒的鼠标消息');
  AAuf.Script.add_func('mousemov,鼠标移动',@_MouseMov,'hwnd,"LRSCM12",x,y','向hwnd窗口发送鼠标坐标更新的消息');
  AAuf.Script.add_func('mousewhl,鼠标滚轮',@_MouseWheel,'hwnd,delta,"LRSCM12",x,y','向hwnd窗口发送鼠标滚轮的消息，delta推荐值为±120');
  AAuf.Script.add_func('post,发送消息',@PostM,'hwnd,msg,w,l','调用Postmessage');
  AAuf.Script.add_func('send,发送消息并等待处理',@SendM,'hwnd,msg,w,l','调用Sendmessage');
  AAuf.Script.add_func('ui.message,消息窗体',@ui_message,'prompt','弹出提示窗体');
  AAuf.Script.add_func('ui.options,选项窗体',@ui_options,'@res,prompt,options[, ...]','弹出选项窗体并返回结果');
  AAuf.Script.add_func('ui.setsync,设置同步器窗体',@ui_set_sync_arv,'index,hwnd','设置第index个同步窗体');

  AAuf.Script.add_func('pushcursor,光标跳转',@PushCursor,'x,y','改变鼠标指针位置，并将当前位置压栈');
  AAuf.Script.add_func('popcursor,光标返回',@PopCursor,'','将鼠标指针位置还原');

  AAuf.Script.add_func('window.top,窗体置顶',@wnd_bring_to_top,'@hwnd','置顶给定句柄的窗体');
  AAuf.Script.add_func('getwnd_v,按名称返回句柄',@getwind_name_visible,'@hwnd,wnd_name','查找名称为wnd_name且可见的窗体句柄');
  AAuf.Script.add_func('getwnd_t,返回置顶窗体',@getwind_top,'@hwnd','返回当前置顶窗体句柄');
  AAuf.Script.add_func('getwnd_s,窗体尺寸信息',@getwind_size,'hwnd,@x,@y,@w,@h','返回指定窗体的尺寸信息');
  AAuf.Script.add_func('wndlist.update,刷新窗体列表',@wndlist_update,'filter,"on/off"','刷新窗体列表，filter为筛选字符串，第2参数规定是否使用正则表达式');
  AAuf.Script.add_func('wndlist.find,递归新窗体查找',@wndlist_find,'filter,"on/off"','查找符合条件的递归窗体，filter为筛选字符串，第2参数规定是否使用正则表达式');

  AAuf.Script.add_func('wndnew.init,查找新窗体初始化',@wndlist_new_init,'','将当前WndList保存用于新窗体查找');
  AAuf.Script.add_func('wndnew.update,计算新窗体',@wndlist_new_update,'hwnd,filter,"on/off"[,-show]','获取新窗体列表，filter为筛选字符串，第2参数规定是否使用正则表达式。带-show参数时打印符合要求的窗体');
  AAuf.Script.add_func('wndnew.pop,获取新窗体',@wndlist_new_pop,'@hwnd','从新窗体列表中获取一个句柄并删除');
  AAuf.Script.add_func('wndnew.empty?,判断是否没有新窗体',@wndlist_new_empty,':label','从新窗体列表中获取一个句柄并删除');

  AAuf.Script.add_func('getpixel,获取像素点',@_GetPixel,'hwnd,x,y,out_var','返回窗体指定像素点颜色');
  AAuf.Script.add_func('getrect,获取画面',@_GetPixelRect,'hwnd,x1,x2,y1,y2,out_var','返回窗体指定矩形范围内像素点颜色');
  AAuf.Script.add_func('ramimg,显示画面',@_RamImage,'col,row,in_var','根据内存变量显示图片');
  AAuf.Script.add_func('ari.get,获取画面ARI',@_ARI_GetRect,'hwnd,@img[,x,y,w,h]','读取窗体画面并保存到ARI图像中');
  AAuf.Script.add_func('ari.dsp,显示画面ARI',@_ARI_Display,'@img','从ARI图像中显示图片');

end;

procedure GlobalExpressionInitialize;
begin
  GlobalExpressionList.TryAddExp('WM_CREATE',narg('','1',''));
  GlobalExpressionList.TryAddExp('WM_DESTROY',narg('','2',''));
  GlobalExpressionList.TryAddExp('WM_MOVE',narg('','3',''));
  GlobalExpressionList.TryAddExp('WM_SIZE',narg('','5',''));
  GlobalExpressionList.TryAddExp('WM_ACTIVATE',narg('','6',''));
  GlobalExpressionList.TryAddExp('WM_SETFOCUS',narg('','7',''));
  GlobalExpressionList.TryAddExp('WM_KILLFOCUS',narg('','8',''));
  GlobalExpressionList.TryAddExp('WM_ENABLE',narg('','10',''));
  GlobalExpressionList.TryAddExp('WM_SETREDRAW',narg('','11',''));
  GlobalExpressionList.TryAddExp('WM_SETTEXT',narg('','12',''));
  GlobalExpressionList.TryAddExp('WM_GETTEXT',narg('','13',''));
  GlobalExpressionList.TryAddExp('WM_GETTEXTLENGTH',narg('','14',''));
  GlobalExpressionList.TryAddExp('WM_PAINT',narg('','15',''));
  GlobalExpressionList.TryAddExp('WM_CLOSE',narg('','16',''));
  GlobalExpressionList.TryAddExp('WM_QUERYENDSESSION',narg('','17',''));
  GlobalExpressionList.TryAddExp('WM_QUIT',narg('','18',''));
  GlobalExpressionList.TryAddExp('WM_QUERYOPEN',narg('','19',''));
  GlobalExpressionList.TryAddExp('WM_ERASEBKGND',narg('','20',''));
  GlobalExpressionList.TryAddExp('WM_SYSCOLORCHANGE',narg('','21',''));
  GlobalExpressionList.TryAddExp('WM_ENDSESSION',narg('','22',''));
  GlobalExpressionList.TryAddExp('WM_SHOWWINDOW',narg('','24',''));
  GlobalExpressionList.TryAddExp('WM_ACTIVATEAPP',narg('','28',''));
  GlobalExpressionList.TryAddExp('WM_FONTCHANGE',narg('','29',''));
  GlobalExpressionList.TryAddExp('WM_TIMECHANGE',narg('','30',''));
  GlobalExpressionList.TryAddExp('WM_CANCELMODE',narg('','31',''));
  GlobalExpressionList.TryAddExp('WM_SETCURSOR',narg('','32',''));
  GlobalExpressionList.TryAddExp('WM_MOUSEACTIVATE',narg('','33',''));
  GlobalExpressionList.TryAddExp('WM_CHILDACTIVATE',narg('','34',''));
  GlobalExpressionList.TryAddExp('WM_QUEUESYNC',narg('','35',''));
  GlobalExpressionList.TryAddExp('WM_GETMINMAXINFO',narg('','36',''));
  GlobalExpressionList.TryAddExp('WM_PAINTICON',narg('','38',''));
  GlobalExpressionList.TryAddExp('WM_ICONERASEBKGND',narg('','39',''));
  GlobalExpressionList.TryAddExp('WM_NEXTDLGCTL',narg('','40',''));
  GlobalExpressionList.TryAddExp('WM_SPOOLERSTATUS',narg('','42',''));
  GlobalExpressionList.TryAddExp('WM_DRAWITEM',narg('','43',''));
  GlobalExpressionList.TryAddExp('WM_MEASUREITEM',narg('','44',''));
  GlobalExpressionList.TryAddExp('WM_DELETEITEM',narg('','45',''));
  GlobalExpressionList.TryAddExp('WM_VKEYTOITEM',narg('','46',''));
  GlobalExpressionList.TryAddExp('WM_CHARTOITEM',narg('','47',''));
  GlobalExpressionList.TryAddExp('WM_SETFONT',narg('','48',''));
  GlobalExpressionList.TryAddExp('WM_GETFONT',narg('','49',''));
  GlobalExpressionList.TryAddExp('WM_SETHOTKEY',narg('','50',''));
  GlobalExpressionList.TryAddExp('WM_GETHOTKEY',narg('','51',''));
  GlobalExpressionList.TryAddExp('WM_QUERYDRAGICON',narg('','55',''));
  GlobalExpressionList.TryAddExp('WM_COMPAREITEM',narg('','57',''));
  GlobalExpressionList.TryAddExp('WM_COMPACTING',narg('','65',''));
  GlobalExpressionList.TryAddExp('WM_WINDOWPOSCHANGING',narg('','70',''));
  GlobalExpressionList.TryAddExp('WM_WINDOWPOSCHANGED',narg('','71',''));
  GlobalExpressionList.TryAddExp('WM_POWER',narg('','72',''));
  GlobalExpressionList.TryAddExp('WM_COPYDATA',narg('','74',''));
  GlobalExpressionList.TryAddExp('WM_CANCELJOURNAL',narg('','75',''));
  GlobalExpressionList.TryAddExp('WM_NOTIFY',narg('','78',''));
  GlobalExpressionList.TryAddExp('WM_INPUTLANGCHANGEREQUEST',narg('','80',''));
  GlobalExpressionList.TryAddExp('WM_INPUTLANGCHANGE',narg('','81',''));
  GlobalExpressionList.TryAddExp('WM_TCARD',narg('','82',''));
  GlobalExpressionList.TryAddExp('WM_HELP',narg('','83',''));
  GlobalExpressionList.TryAddExp('WM_USERCHANGED',narg('','84',''));
  GlobalExpressionList.TryAddExp('WM_NOTIFYFORMAT',narg('','85',''));
  GlobalExpressionList.TryAddExp('WM_CONTEXTMENU',narg('','123',''));
  GlobalExpressionList.TryAddExp('WM_STYLECHANGING',narg('','124',''));
  GlobalExpressionList.TryAddExp('WM_STYLECHANGED',narg('','125',''));
  GlobalExpressionList.TryAddExp('WM_DISPLAYCHANGE',narg('','126',''));
  GlobalExpressionList.TryAddExp('WM_GETICON',narg('','127',''));
  GlobalExpressionList.TryAddExp('WM_SETICON',narg('','128',''));
  GlobalExpressionList.TryAddExp('WM_NCCREATE',narg('','129',''));
  GlobalExpressionList.TryAddExp('WM_NCDESTROY',narg('','130',''));
  GlobalExpressionList.TryAddExp('WM_NCCALCSIZE',narg('','131',''));
  GlobalExpressionList.TryAddExp('WM_NCHITTEST',narg('','132',''));
  GlobalExpressionList.TryAddExp('WM_NCPAINT',narg('','133',''));
  GlobalExpressionList.TryAddExp('WM_NCACTIVATE',narg('','134',''));
  GlobalExpressionList.TryAddExp('WM_GETDLGCODE',narg('','135',''));
  GlobalExpressionList.TryAddExp('WM_NCMOUSEMOVE',narg('','160',''));
  GlobalExpressionList.TryAddExp('WM_NCLBUTTONDOWN',narg('','161',''));
  GlobalExpressionList.TryAddExp('WM_NCLBUTTONUP',narg('','162',''));
  GlobalExpressionList.TryAddExp('WM_NCLBUTTONDBLCLK',narg('','163',''));
  GlobalExpressionList.TryAddExp('WM_NCRBUTTONDOWN',narg('','164',''));
  GlobalExpressionList.TryAddExp('WM_NCRBUTTONUP',narg('','165',''));
  GlobalExpressionList.TryAddExp('WM_NCRBUTTONDBLCLK',narg('','166',''));
  GlobalExpressionList.TryAddExp('WM_NCMBUTTONDOWN',narg('','167',''));
  GlobalExpressionList.TryAddExp('WM_NCMBUTTONUP',narg('','168',''));
  GlobalExpressionList.TryAddExp('WM_NCMBUTTONDBLCLK',narg('','169',''));
  GlobalExpressionList.TryAddExp('WM_KEYDOWN',narg('','256',''));
  GlobalExpressionList.TryAddExp('WM_KEYUP',narg('','257',''));
  GlobalExpressionList.TryAddExp('WM_CHAR',narg('','258',''));
  GlobalExpressionList.TryAddExp('WM_DEADCHAR',narg('','259',''));
  GlobalExpressionList.TryAddExp('WM_SYSKEYDOWN',narg('','260',''));
  GlobalExpressionList.TryAddExp('WM_SYSKEYUP',narg('','261',''));
  GlobalExpressionList.TryAddExp('WM_SYSCHAR',narg('','262',''));
  GlobalExpressionList.TryAddExp('WM_SYSDEADCHAR',narg('','263',''));
  GlobalExpressionList.TryAddExp('WM_INITDIALOG',narg('','272',''));
  GlobalExpressionList.TryAddExp('WM_COMMAND',narg('','273',''));
  GlobalExpressionList.TryAddExp('WM_SYSCOMMAND',narg('','274',''));
  GlobalExpressionList.TryAddExp('WM_TIMER',narg('','275',''));
  GlobalExpressionList.TryAddExp('WM_HSCROLL',narg('','276',''));
  GlobalExpressionList.TryAddExp('WM_VSCROLL',narg('','277',''));
  GlobalExpressionList.TryAddExp('WM_INITMENU',narg('','278',''));
  GlobalExpressionList.TryAddExp('WM_INITMENUPOPUP',narg('','279',''));
  GlobalExpressionList.TryAddExp('WM_MENUSELECT',narg('','287',''));
  GlobalExpressionList.TryAddExp('WM_MENUCHAR',narg('','288',''));
  GlobalExpressionList.TryAddExp('WM_ENTERIDLE',narg('','289',''));
  GlobalExpressionList.TryAddExp('WM_CTLCOLORMSGBOX',narg('','306',''));
  GlobalExpressionList.TryAddExp('WM_CTLCOLOREDIT',narg('','307',''));
  GlobalExpressionList.TryAddExp('WM_CTLCOLORLISTBOX',narg('','308',''));
  GlobalExpressionList.TryAddExp('WM_CTLCOLORBTN',narg('','309',''));
  GlobalExpressionList.TryAddExp('WM_CTLCOLORDLG',narg('','310',''));
  GlobalExpressionList.TryAddExp('WM_CTLCOLORSCROLLBAR',narg('','311',''));
  GlobalExpressionList.TryAddExp('WM_CTLCOLORSTATIC',narg('','312',''));
  GlobalExpressionList.TryAddExp('WM_MOUSEMOVE',narg('','512',''));
  GlobalExpressionList.TryAddExp('WM_LBUTTONDOWN',narg('','513',''));
  GlobalExpressionList.TryAddExp('WM_LBUTTONUP',narg('','514',''));
  GlobalExpressionList.TryAddExp('WM_LBUTTONDBLCLK',narg('','515',''));
  GlobalExpressionList.TryAddExp('WM_RBUTTONDOWN',narg('','516',''));
  GlobalExpressionList.TryAddExp('WM_RBUTTONUP',narg('','517',''));
  GlobalExpressionList.TryAddExp('WM_RBUTTONDBLCLK',narg('','518',''));
  GlobalExpressionList.TryAddExp('WM_MBUTTONDOWN',narg('','519',''));
  GlobalExpressionList.TryAddExp('WM_MBUTTONUP',narg('','520',''));
  GlobalExpressionList.TryAddExp('WM_MBUTTONDBLCLK',narg('','521',''));
  GlobalExpressionList.TryAddExp('WM_MOUSEWHEEL',narg('','522',''));
  GlobalExpressionList.TryAddExp('WM_PARENTNOTIFY',narg('','528',''));
  GlobalExpressionList.TryAddExp('WM_ENTERMENULOOP',narg('','529',''));
  GlobalExpressionList.TryAddExp('WM_EXITMENULOOP',narg('','530',''));
  GlobalExpressionList.TryAddExp('WM_SIZING',narg('','532',''));
  GlobalExpressionList.TryAddExp('WM_CAPTURECHANGED',narg('','533',''));
  GlobalExpressionList.TryAddExp('WM_MOVING',narg('','534',''));
  GlobalExpressionList.TryAddExp('WM_POWERBROADCAST',narg('','536',''));
  GlobalExpressionList.TryAddExp('WM_DEVICECHANGE',narg('','537',''));
  GlobalExpressionList.TryAddExp('WM_MDICREATE',narg('','544',''));
  GlobalExpressionList.TryAddExp('WM_MDIDESTROY',narg('','545',''));
  GlobalExpressionList.TryAddExp('WM_MDIACTIVATE',narg('','546',''));
  GlobalExpressionList.TryAddExp('WM_MDIRESTORE',narg('','547',''));
  GlobalExpressionList.TryAddExp('WM_MDINEXT',narg('','548',''));
  GlobalExpressionList.TryAddExp('WM_MDIMAXIMIZE',narg('','549',''));
  GlobalExpressionList.TryAddExp('WM_MDITILE',narg('','550',''));
  GlobalExpressionList.TryAddExp('WM_MDICASCADE',narg('','551',''));
  GlobalExpressionList.TryAddExp('WM_MDIICONARRANGE',narg('','552',''));
  GlobalExpressionList.TryAddExp('WM_MDIGETACTIVE',narg('','553',''));
  GlobalExpressionList.TryAddExp('WM_MDISETMENU',narg('','560',''));
  GlobalExpressionList.TryAddExp('WM_CUT',narg('','768',''));
  GlobalExpressionList.TryAddExp('WM_COPY',narg('','769',''));
  GlobalExpressionList.TryAddExp('WM_PASTE',narg('','770',''));
  GlobalExpressionList.TryAddExp('WM_CLEAR',narg('','771',''));
  GlobalExpressionList.TryAddExp('WM_UNDO',narg('','772',''));
  GlobalExpressionList.TryAddExp('WM_DESTROYCLIPBOARD',narg('','775',''));
  GlobalExpressionList.TryAddExp('WM_DRAWCLIPBOARD',narg('','776',''));
  GlobalExpressionList.TryAddExp('WM_PAINTCLIPBOARD',narg('','777',''));
  GlobalExpressionList.TryAddExp('WM_SIZECLIPBOARD',narg('','779',''));
  GlobalExpressionList.TryAddExp('WM_ASKCBFORMATNAME',narg('','780',''));
  GlobalExpressionList.TryAddExp('WM_CHANGECBCHAIN',narg('','781',''));
  GlobalExpressionList.TryAddExp('WM_HSCROLLCLIPBOARD',narg('','782',''));
  GlobalExpressionList.TryAddExp('WM_QUERYNEWPALETTE',narg('','783',''));
  GlobalExpressionList.TryAddExp('WM_PALETTEISCHANGING',narg('','784',''));
  GlobalExpressionList.TryAddExp('WM_PALETTECHANGED',narg('','785',''));
  GlobalExpressionList.TryAddExp('WM_HOTKEY',narg('','786',''));

  GlobalExpressionList.TryAddExp('k_bksp',narg('','8',''));
  GlobalExpressionList.TryAddExp('k_tab',narg('','9',''));
  GlobalExpressionList.TryAddExp('k_clear',narg('','12',''));
  GlobalExpressionList.TryAddExp('k_enter',narg('','13',''));
  GlobalExpressionList.TryAddExp('k_shift',narg('','16',''));
  GlobalExpressionList.TryAddExp('k_ctrl',narg('','17',''));
  GlobalExpressionList.TryAddExp('k_alt',narg('','18',''));
  GlobalExpressionList.TryAddExp('k_pause',narg('','19',''));
  GlobalExpressionList.TryAddExp('k_capelk',narg('','20',''));
  GlobalExpressionList.TryAddExp('k_esc',narg('','27',''));
  GlobalExpressionList.TryAddExp('k_space',narg('','32',''));
  GlobalExpressionList.TryAddExp('k_pgup',narg('','33',''));
  GlobalExpressionList.TryAddExp('k_pgdn',narg('','34',''));
  GlobalExpressionList.TryAddExp('k_end',narg('','35',''));
  GlobalExpressionList.TryAddExp('k_home',narg('','36',''));
  GlobalExpressionList.TryAddExp('k_left',narg('','37',''));
  GlobalExpressionList.TryAddExp('k_up',narg('','38',''));
  GlobalExpressionList.TryAddExp('k_right',narg('','39',''));
  GlobalExpressionList.TryAddExp('k_down',narg('','40',''));
  GlobalExpressionList.TryAddExp('k_sel',narg('','41',''));
  GlobalExpressionList.TryAddExp('k_print',narg('','42',''));
  GlobalExpressionList.TryAddExp('k_exec',narg('','43',''));
  GlobalExpressionList.TryAddExp('k_snapshot',narg('','44',''));
  GlobalExpressionList.TryAddExp('k_ins',narg('','45',''));
  GlobalExpressionList.TryAddExp('k_del',narg('','46',''));
  GlobalExpressionList.TryAddExp('k_help',narg('','47',''));
  GlobalExpressionList.TryAddExp('k_lwin',narg('','91',''));
  GlobalExpressionList.TryAddExp('k_rwin',narg('','92',''));
  GlobalExpressionList.TryAddExp('k_f1',narg('','112',''));
  GlobalExpressionList.TryAddExp('k_f2',narg('','113',''));
  GlobalExpressionList.TryAddExp('k_f3',narg('','114',''));
  GlobalExpressionList.TryAddExp('k_f4',narg('','115',''));
  GlobalExpressionList.TryAddExp('k_f5',narg('','116',''));
  GlobalExpressionList.TryAddExp('k_f6',narg('','117',''));
  GlobalExpressionList.TryAddExp('k_f7',narg('','118',''));
  GlobalExpressionList.TryAddExp('k_f8',narg('','119',''));
  GlobalExpressionList.TryAddExp('k_f9',narg('','120',''));
  GlobalExpressionList.TryAddExp('k_f10',narg('','121',''));
  GlobalExpressionList.TryAddExp('k_f11',narg('','122',''));
  GlobalExpressionList.TryAddExp('k_f12',narg('','123',''));
  GlobalExpressionList.TryAddExp('k_numlk',narg('','144',''));
  GlobalExpressionList.TryAddExp('k_lshift',narg('','160',''));
  GlobalExpressionList.TryAddExp('k_rshift',narg('','161',''));
  GlobalExpressionList.TryAddExp('k_lctrl',narg('','162',''));
  GlobalExpressionList.TryAddExp('k_rctrl',narg('','163',''));
  GlobalExpressionList.TryAddExp('k_lalt',narg('','164',''));
  GlobalExpressionList.TryAddExp('k_ralt',narg('','165',''));
end;

