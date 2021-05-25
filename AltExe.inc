 procedure AltExe(c: longint; s: ArrStr; const short, long: UnicodeString; var e:longword);
 const
  vr = 'er';
  vrr = 'envar';
  vl = 'el';
  val = 'enval';

 var
    SEInfo: TShellExecuteInfoW;
    ExitCode: longword;
    i: integer;
    ProcID: longword;
    HProcWin: longword;
    parent_handle: longint = 0;
    hide: boolean = False;
    timeout_wait_window: integer = 3000;
    timeout: longint = 0;
    no_wait: boolean = True;
    runfile, params, dir: UnicodeString;
    sl: integer;
    Show: UnicodeString = '';
    lock: boolean = False;
    childs: PIDS;
    no_child: boolean = True;
    wait_child:boolean =false;
    sp, lp: UnicodeString;
   // create:boolean=false;
    //x:shortstring;

 begin
    runfile := gp(c, s, short, long);
    if (runfile = '')or(runfile = ':i:')or(runfile = ':nil:')or(runfile = ':nothing:') then Exit;
    if short = 'r' then sp := '' else sp := short;
    if long = 'run' then lp := '' else lp := long + '-';
    runfile := WorkAltVars(runfile, c, s,1);
   // writeln('Pos(dots, runfile)=',Pos(dots, runfile));
    //writeln('Pos(sp, runfile)=',Pos(space, runfile));
    //writeln('Pos(dq, runfile)=',Pos(dq, runfile));
    if (Pos(dots, runfile) = 2)and(Pos(space, runfile) > 0)and(Pos(dq, runfile) = 0) then runfile:= dq+runfile+dq;
    params := gp(c, s, sp + 'p', lp + 'par');
    //writeln('params=',params);
    if params<>'' then params := WorkAltVars(params, c, s,0);
    if (CharCount(dots, params) = 1)and(Pos(dots, params) = 2)and(Pos(space, params) > 0)and(Pos(dq, params) = 0) then params:= dq+params+dq;

    //writeln('params=',params);
    // writeln(params);
    //if hp(c,s,'pq','par-quote') then params:=QuotingParams(params);
   // writeln(params);
   // readln;
    if (Pos(dots, params) = 2)and(Pos(space, params) > 0)and(Pos(dq, params) = 0)and(Pos('\', params)=0) then params:= dq+params+dq;
    //if ExistsRes(c, s,create) then no_wait := False;
    dir := gp(c, s, sp + 'd', lp + 'dir');
    if dir = '' then dir := GetCurrentDir;
    dir := WorkAltVars(dir, c, s,1);
    //if (Pos(dots, dir) = 2)and(Pos(space, dir) > 0)and(Pos(dq, dir) <> 1) then dir:= dq+dir+dq;
    if dir[Length(dir)]<>'\' then dir:=dir+'\';
    WorkVars(c, s, short, long);
    if hp(c, s, sp + 'nn', lp + 'no-admin') then SetEnvironmentVariable(PWideChar('__COMPAT_LAYER'), PWideChar('RUNASINVOKER'));
    if hp(c, s, 'tww', 'timeout-wait-window') then timeout_wait_window := StrToInt(gp(c, s, 'tww', 'timeout-wait-window'));
    if StrIn(lp, waits_long) or StrIn(sp, waits_short) then
    if hp(c, s, sp + 'nw', lp + 'nowait') = False then no_wait := False;
    if hp(c, s, sp + 'w', lp + 'wait') then no_wait := False;
    if hp(c, s, '1', 'one') then no_wait := False;
    if hp(c, s, sp + 'f', lp + 'after') then no_wait := False;
    if hp(c, s, sp + 'l', lp + 'lock') then
    begin
      no_wait := False;
      lock := True;
    end;

    if hp(c, s, sp + 'wc', lp + 'wait-child') then wait_child:=true;
    if no_wait = False then timeout := StrToInt(gp(c, s, sp + 't', lp + 'timeout'));

    if hp(c, s, sp + 'h', lp + 'hide') then hide := True;
    if hp(c, s, sp + 'mx', lp + 'maximize') then Show := 'max';
    if hp(c, s, sp + 'mn', lp + 'minimize') then Show := 'min';
    ExitCode := 0;
    FillChar(SEInfo, SizeOf(SEInfo), 0);
    SEInfo.cbSize := SizeOf(TShellExecuteInfoW);
    with SEInfo do
    begin
      fMask := $00000040;
      Wnd := GetForegroundWindow;
      if hp(c, s, sp + 'n', lp + 'admin') then
      begin
        lpVerb :=  PWideChar(WideString('runas'));
        //if length(params)>2 then if (params[1]=dq)and(params[length(params)]=dq) then params:=copy(params,2,Length(params)-2);
       // if pos(dq,params)>0 then params:=StringReplace(params,dq,':s:',[rfReplaceAll]);
        if pos(dq,params)<>0 then params:='--run='+runfile+' --par='+sq+params+sq
        else
         if (pos(space,params)<>0) then
          begin
           if (CharCount(dots,params)>1) then params:='--run='+runfile+' --par='+sq+params+sq
           else
            if (CharCount(dots,params)=1) then params:='--run='+runfile+' --par='+dq+params+dq
            else params:='--run='+runfile+' --par='+params
          end
          else
            params:='--run='+runfile+' --par='+sq+params+sq;
        if hide then params:=params+' --hide';
        if hp(c, s, sp + 'mx', lp + 'maximize') then params:=params+' --maximize';
        if hp(c, s, sp + 'mn', lp + 'minimize') then params:=params+' --minimize';
        if hp(c, s, 'tww', 'timeout-wait-window') then  params:=params+' -tww';
        if hp(c, s, sp + 'nw', lp + 'nowait') then params:=params+' --nowait';
        if (hp(c, s, sp + 'f', lp + 'after'))or(hp(c, s, sp + 'l', lp + 'lock'))or(hp(c, s, sp + 'w', lp + 'wait'))or(hp(c, s, sp + 'wc', lp + 'wait-child')) then
        begin
          params:=params+' --wait';
          params:=params+' --wait-child';
          wait_child:=true;
        end;
        if hp(c, s, sp + 't', lp + 'timeout') then params:=params+' --timeout='+gp(c, s, sp + 't', lp + 'timeout');

        if hp(c, s, vr, vrr) then  params:=params+' --envar='+gp(c, s, vr, vrr);
        if hp(c, s, vl, val) then  params:=params+' --enval='+gp(c, s, vl, val);
          for i := 2 to 9 do
    if hp(c, s, vr + IntToStr(i), vrr + IntToStr(i)) then params:=params+' --envar'+IntToStr(i)+'='+gp(c, s, vr + IntToStr(i), vrr + IntToStr(i));
       for i := 2 to 9 do
     if hp(c, s, vl + IntToStr(i), val + IntToStr(i)) then params:=params+' --enval'+IntToStr(i)+'='+gp(c, s, vl + IntToStr(i), val + IntToStr(i));

       if (sp<>'')and(lp<>'') then
       begin
         if hp(c, s, sp+vr, lp+vrr) then  params:=params+' --envar='+gp(c, s, sp+vr, lp+vrr);
        if hp(c, s, sp+vl, lp+val) then  params:=params+' --enval='+gp(c, s, sp+vl, lp+val);
          for i := 2 to 9 do
    if hp(c, s, sp+vr + IntToStr(i), lp+vrr + IntToStr(i)) then params:=params+' --envar'+IntToStr(i)+'='+gp(c, s, sp+vr + IntToStr(i), lp+vrr + IntToStr(i));
       for i := 2 to 9 do
     if hp(c, s, sp+vl + IntToStr(i), lp+val + IntToStr(i)) then params:=params+' --enval'+IntToStr(i)+'='+gp(c, s, sp+vl + IntToStr(i), lp+val + IntToStr(i));

       end;

       if (sp='')and(lp='') then
       begin
         if hp(c, s, 'r'+vr, 'run-'+vrr) then  params:=params+' --envar='+gp(c, s, 'r'+vr, 'run-'+vrr);
        if hp(c, s, 'r'+vl, 'run-'+val) then  params:=params+' --enval='+gp(c, s, 'r'+vl, 'run-'+val);
          for i := 2 to 9 do
    if hp(c, s, 'r'+vr + IntToStr(i), 'run-'+vrr + IntToStr(i)) then params:=params+' --envar'+IntToStr(i)+'='+gp(c, s, 'r'+vr + IntToStr(i), 'run-'+vrr + IntToStr(i));
       for i := 2 to 9 do
     if hp(c, s, 'r'+vl + IntToStr(i), 'run-'+val + IntToStr(i)) then params:=params+' --enval'+IntToStr(i)+'='+gp(c, s, 'r'+vl + IntToStr(i), 'run-'+val + IntToStr(i));

       end;


       runfile:=s[0];

        dir:=GetCurrentdir;
        hide:=false;
        Show:='';

      end;
      lpParameters := PWideChar(WideString(params));
      lpFile := PWideChar(WideString(runfile));
      lpDirectory := PWideChar(WideString(dir));
      nShow := SW_SHOW;
      if hide then nShow := SW_HIDE else
      begin
        if Show = 'max' then nShow := SW_MAXIMIZE;
        if Show = 'min' then nShow := SW_MINIMIZE;
      end;
    end;
    if hp(c, s, sp + 'df', lp + 'delay-first') then
    begin
      sl := 0;
      sl := StrToInt(gp(c, s, sp + 'df', lp + 'delay-first'));
      if sl > 0 then Sleep(sl);
    end;
    if hp(c, s, sp + 'dl', lp + 'delay-last') then no_wait := False;
    if lock then BlockInput(True);
    {$IFDEF DBG}
    writeln('runfile:');
    writeln(runfile);
    writeln;
    writeln('params: ');
    writeln(params);
    writeln;
    writeln('dir: ');
    writeln(dir);
    writeln;
    if no_wait then writeln('wait process: false') else writeln('wait process: true');
    writeln;
    Writeln('Press Enter to run...');
    readln;
    {$ENDIF}
    if ShellExecuteExW(@SEInfo) then
    begin
      i := 0;
      HProcWin := 0;
      ProcID := GetProcessId(SEInfo.hProcess);
      repeat
        sleep(100);
        HProcWin := FindMainWindow(ProcID);
        GetExitCodeProcess(SEInfo.hProcess, ExitCode);
        i := i + 100;
        if wait_child then  no_child := NoChildPresent(ProcID, childs);
      until (HProcWin > 0) or (i > timeout_wait_window) or (ExitCode <> $103);
      if HProcWin > 0 then
        if not hide then
        begin
          AllowSetForegroundWindow(ProcID);
          SetForegroundWindow(HProcWin);
          SetActiveWindow(HProcWin);
          SendMessage(parent_handle, 8, 0, 0);
          SetFocus(HProcWin);
          if Show = '' then ShowWindow(HProcWin, SW_RESTORE) else
          begin
            if Show = 'max' then ShowWindow(HProcWin, SW_MAXIMIZE);
            if Show = 'min' then ShowWindow(HProcWin, SW_MINIMIZE);
          end;
        end
        else
        begin
          ShowWindow(HProcWin, SW_MINIMIZE);
          ShowWindow(HProcWin, SW_HIDE);
        end;
      i := 0;
      if timeout > 0 then no_wait := False;
      //
      //if not no_wait then writeln(long+' wait') else writeln(long+' NO wait');
      //
      if no_wait = False then
        if (ExitCode = $103) or wait_child then
          repeat
            GetExitCodeProcess(SEInfo.hProcess, ExitCode);
            if wait_child then no_child := NoChildPresent(ProcID, childs);
            sleep(100);
            if timeout > 0 then i := i + 100;
          until ((ExitCode <> $103) and no_child) or ((timeout > 0) and (i > timeout));
    end;
    e:=ExitCode;
    SetEnvironmentVariable(PWideChar('exitcode'), PWideChar(inttostr(e)));
    if lock then BlockInput(False);
    if hp(c, s, sp + 'dl', lp + 'delay-last') then
    begin
      sl := 0;
      sl := StrToInt(gp(c, s, sp + 'df', lp + 'delay-last'));
      if sl > 0 then Sleep(sl);
    end;
    //DelRes(c, s,create);

 end;
