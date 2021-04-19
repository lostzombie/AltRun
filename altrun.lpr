program altrun;
{$PASCALMAINNAME wWinMainCRTStartup}
{$define DBG}
uses
  AltSys, AltExt, AltCmd, AltUnit;
var
  c: longint;
  s: ArrStr;
  state: TKeyboardState;
  short: UnicodeString = '';
  long: UnicodeString = '';
  shortR: UnicodeString = '';
  longR: UnicodeString = '';
  run_exist_yes: boolean = False;
  run_else_yes: boolean = False;
  hp_exist: boolean = False;
  hp_else: boolean = False;
  msg: longword = 0;
  MsgText, Caption: PWidechar;
  e, exitcode, i: longword;
  press_not_bind: boolean = False;
//create:boolean=false;
{$R *.res}

{$INCLUDE AltExe.inc}

begin
  GetKeyboardState(state);
  GetAllParams(c, s);
  {$IFDEF DBG}
  Writeln;
  Writeln('Arguments');
  Writeln;
  {$ENDIF}
  WorkAllParams(c, s);
  {$IFDEF DBG}
  for i := 0 to c - 1 do writeln(s[i]);
  Writeln;
  {$ENDIF}
  Caption := PWideChar(ExtractFileName(s[0]));
  if GetUserDefaultLCID = 1049 then MsgText := PWidechar('Запущен другой экземпляр ' + ExtractFileName(s[0]))
  else MsgText := PWidechar('Another instance of ' + ExtractFileName(s[0]) + '  started');
  if hp(c, s, '1', 'one') then
    repeat
      Msg := 0;
      if HasProcess(s[0], 0, gp(c, s, '1', 'one') = 'name', ExtractFilePath(s[0])) then
        if not hp(c, s, '1nm', 'one-no-message') then
        begin
          Msg := MessageBoxEx(0, MsgText, Caption, $5 + $100 + $00000030, $0000);
        end
        else halt;
    until Msg <> 4;
  if Msg = 2 then Halt;
  if ((State[vk_Control] and 128) = 0) and ((State[vk_Shift] and 128) = 0) and ((State[vk_Menu] and 128) <> 0) then
    if (hp(c, s, 'a', 'alt')) then
    begin
      short := 'a';
      long := alt;
    end
    else press_not_bind := True;
  if ((State[vk_Control] and 128) = 0) and ((State[vk_Shift] and 128) <> 0) and ((State[vk_Menu] and 128) = 0) then
    if (hp(c, s, 's', 'shift')) then
    begin
      short := 's';
      long := shift;
    end
    else press_not_bind := True;
  if ((State[vk_Control] and 128) <> 0) and ((State[vk_Shift] and 128) = 0) and ((State[vk_Menu] and 128) = 0) then
    if (hp(c, s, 'c', 'ctrl')) then
    begin
      short := 'c';
      long := ctrl;
    end
    else press_not_bind := True;
  if ((State[vk_Control] and 128) = 0) and ((State[vk_Shift] and 128) <> 0) and ((State[vk_Menu] and 128) <> 0) then
    if (hp(c, s, 'as', 'alt-shift')) then
    begin
      short := 'as';
      long := alt + hyp + shift;
    end
    else press_not_bind := True;
  if ((State[vk_Control] and 128) <> 0) and ((State[vk_Shift] and 128) = 0) and ((State[vk_Menu] and 128) <> 0) then
    if (hp(c, s, 'ca', 'ctrl-alt')) then
    begin
      short := 'ca';
      long := ctrl + hyp + alt;
    end
    else press_not_bind := True;
  if ((State[vk_Control] and 128) <> 0) and ((State[vk_Shift] and 128) <> 0) and ((State[vk_Menu] and 128) = 0) then
    if (hp(c, s, 'cs', 'ctrl-shift')) then
    begin
      short := 'cs';
      long := ctrl + hyp + shift;
    end
    else press_not_bind := True;
  if ((State[vk_Control] and 128) <> 0) and ((State[vk_Shift] and 128) <> 0) and ((State[vk_Menu] and 128) <> 0) then
    if (hp(c, s, 'cas', 'ctrl-alt-shift')) then
    begin
      short := 'cas';
      long := ctrl + hyp + alt + hyp + shift;
    end
    else press_not_bind := True;
  if ((State[vk_RBUTTON] and 128) <> 0) then
    if (hp(c, s, 'rb', 'right-button')) then
    begin
      short := 'rb';
      long := 'right-button';
    end
    else press_not_bind := True;
  {$IFDEF DBG}
  if long<>'' then  writeln('pressed keys: ', long);
  if press_not_bind then writeln('Pressed keys, but not binded');
  writeln;
  if not (hp(c, s, 'i', 'ignore-undef-bind')or(Exists(ExtractFilePath(s[0])+'ignore-undef-bind'))) then
  if press_not_bind then
  begin
    writeln('Press Enter');
    readln;
  end;
  {$ENDIF}
  if press_not_bind then
    if hp(c, s, 'i', 'ignore-undef-bind')or(Exists(ExtractFilePath(s[0])+'ignore-undef-bind')) then
    begin
      if short = '' then shortR := 'r' else shortR := short;
      if long = '' then longR := 'run' else
      begin
        longR := long;
        long := long + '-';
      end;
    end
    else Halt
  else
  begin
    if short = '' then shortR := 'r' else shortR := short;
    if long = '' then longR := 'run' else
    begin
      longR := long;
      long := long + '-';
    end;
  end;
  if (short <> '') or (gp(c, s, 'r', 'run') <> '') then
  begin
    Caption := PWideChar(ExtractFileName(s[0]));
    if GetUserDefaultLCID = 1049 then MsgText := PWidechar('Запущен другой экземпляр ' + gp(c, s, shortR, longR))
    else MsgText := PWidechar('Another instance of ' + gp(c, s, shortR, longR) + '  started');
    if hp(c, s, short + '1t', long + 'one-target') then
      repeat
        Msg := 0;
        if HasProcess(gp(c, s, shortR, longR), 1, gp(c, s, short + '1t', long + 'one-target') = 'name', ExtractFilePath(s[0])) then
          if not hp(c, s, '1nm', 'one-no-message') then Msg := MessageBoxEx(0, MsgText, Caption, $5 + $100 + $00000030, $0000) else halt;
      until Msg <> 4;
    if Msg = 2 then Halt;
    if hp(c, s, short + 'b', long + 'before') then AltExe(c, s, short + 'b', long + 'before', e);
    if hp(c, s, short + 'x', long + 'exist') then hp_exist := True;
    if hp(c, s, short + 'e', long + 'else') then hp_else := True;
    if hp_exist then
    begin
      if hp(c, s, short + 'x1', long + 'if-exist') and (gp(c, s, short + 'x1', long + 'if-exist') <> '') then if Exists(WorkAltVars(gp(c, s, short + 'x1', long + 'if-exist'), c, s, 1)) then run_exist_yes := True;
      if hp(c, s, short + 'x2', long + 'if-exist2') and (gp(c, s, short + 'x2', long + 'if-exist2') <> '') then if Exists(WorkAltVars(gp(c, s, short + 'x2', long + 'if-exist2'), c, s, 1)) then run_exist_yes := True;
      if hp(c, s, short + 'x3', long + 'if-exist3') and (gp(c, s, short + 'x3', long + 'if-exist3') <> '') then if Exists(WorkAltVars(gp(c, s, short + 'x3', long + 'if-exist3'), c, s, 1)) then run_exist_yes := True;
      if hp(c, s, short + 'nx1', long + 'if-no-exist') and (gp(c, s, short + 'nx1', long + 'if-no-exist') <> '') then if not Exists(WorkAltVars(gp(c, s, short + 'nx1', long + 'if-no-exist'), c, s, 1)) then run_exist_yes := True;
      if hp(c, s, short + 'nx2', long + 'if-no-exist2') and (gp(c, s, short + 'nx2', long + 'if-no-exist2') <> '') then if not Exists(WorkAltVars(gp(c, s, short + 'nx2', long + 'if-no-exist2'), c, s, 1)) then run_exist_yes := True;
      if hp(c, s, short + 'nx3', long + 'if-no-exist3') and (gp(c, s, short + 'nx3', long + 'if-no-exist3') <> '') then if not Exists(WorkAltVars(gp(c, s, short + 'nx3', long + 'if-no-exist3'), c, s, 1)) then run_exist_yes := True;
      if run_exist_yes then AltExe(c, s, short + 'x', long + 'exist', e);
    end;
    if hp_else then
    begin
      if not Exists(WorkAltVars(gp(c, s, shortR, longR), c, s, 1)) then run_else_yes := True;
      if run_else_yes then AltExe(c, s, short + 'e', long + 'else', e);
    end;
    if hp(c, s, short + 'u', long + 'rerun') and (run_exist_yes or run_else_yes) then
    begin
      Sleep(100);
      AltExe(c, s, shortR, longR, e);
    end;
    if not (run_exist_yes or run_else_yes) then AltExe(c, s, shortR, longR, e);
    exitcode := e;
    if hp(c, s, short + 'f', long + 'after') then AltExe(c, s, short + 'f', long + 'after', e);
  end;
  Halt(exitcode);
end.
