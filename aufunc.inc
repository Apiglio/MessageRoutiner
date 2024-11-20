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


