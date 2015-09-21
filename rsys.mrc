; r.chan by vaaz
; v1.0
; member-based channel control script.
; includes dual-network channel-link via relay
; Relay can be disabled.
; more information @ https://github.com/cloudCase/r.chan

; ### SETTINGS ###

; r.chan_chan - Channel for the script to run on.
alias -l r.chan_chan { return #respect }
; r.chan_pre - Prefix for messages
alias -l r.chan_pre { return (respect) }

; ### LOAD EVENT ###
on *:LOAD: {
  r.echo load Welcome to r.chan - version 1.0
  r.echo load Unsetting any previous variables for r.chan (%r.*)
  unset %r.*
  r.echo load Checking for existing settings.ini
  if ($exists(r.chan\settings.ini)) { r.echo load Settings file found. }
  r.echo load Load of r.chan complete.
}

; Global Aliases
alias r.chan {
  if ($1 == +u) { $iif($2,r.auser $2,r.echo error syntax: /r.chan +u [user]) }
  elseif ($1 == -u) { $iif($2,r.deluser $2,r.echo error syntax: /r.chan -u [user]) }
  elseif ($1 == +o) { $iif($2,r.addown $2,r.echo error syntax: /r.chan +o [user]) }
  elseif ($1 == -o) { $iif($2,r.delown $2,r.echo error syntax: /r.chan -o [user]) }
  elseif ($1 == -m) { $iif($2,r.msg Console_Message $2-,r.echo error syntax: /r.chan -m [message]) }
  elseif ($1 == +m) { r.echo memlist $r.memlist }
}
; Local Aliases
alias -l r.add { r.auser $2 | r.msg useradd $1 added $2 to the members list. }
alias -l r.oadd { r.addown $2 | r.msg owneradd $1 added $2 to the owner list }
alias -l r.auser { writeini r.chan\settings.ini members all $addtok($r.memlist,$1,32) | r.echo useradd User $1 added as member. }
alias -l r.deluser { writeini r.chan\settings.ini members all $remtok($r.memlist,$2) | r.echo userdel User $1 removed from members list. }
alias -l r.addown { writeini r.chan\settings.ini members own $addtok($r.ownlist,$1,32) | r.echo ownadd User $1 added to Owner list. }
alias -l r.delown { writeini r.chan\settings.ini members own $remtok($r.ownlist,$1) | r.echo owndel User $1 removed from Owner list. }
alias -l r.ownlist { return $readini(r.chan\settings.ini,members,own) }
alias -l r.memlist { return $readini(r.chan\settings.ini,members,all) }
alias -l r.mem { return $iif($1 isin $r.memlist,$true,$null) }
alias -l r.own { return $iif($1 isin $r.ownlist,$true,$null) }
alias -l r.msg { msg $r.chan_chan $r.chan_pre $+([,$1,]) $2- }
alias -l r.echo { echo -agt $r.chan_pre $+([,$1,]) $2- }
alias -l r.dbg { if (!$window(@r.chan)) { window -E @r.chan } | echo -gt @r.chan $r.chan_pre [debug] $1- }
alias -l r.invite { notice $2 You have been invited to join $r.chan_chan. | r.msg invite $2 has been invited. }
alias -l r.topic { topic $r.chan_chan $1- | set %r.topic $1- }
alias -l r.check { return $iif($r.own($1),owner,$iif($r.mem($1),member,zero)) }
alias -l r.relay {
  if ($cid == %r.relay) { scid 1 msg $r.chan_chan $+([,$1,]) $2- }
  elseif ($cid == 1) { scid %r.relay msg $r.chan_chan $+([,$1,]) $2- }
  else { r.dbg Relay error. - cid: $cid - relay cid: %r.relay - message: $1- }
}

; Text event
on *:TEXT:*:#: {
  if ($chan !== $r.chan_chan) { halt }
  if ($r.mem($nick)) {
    if ($1 == .r) {
      r.dbg command recieved. - $1-
      if ($2 == help) { 
        if (!$3) { r.msg help Commands are: invite,check | r.msg help Owner Commands are: topic,add | r.msg help type .r help [command] for help with that command. }
        elseif ($3 == invite) { r.msg help syntax: .r invite [user] | r.msg help invites a user the the channel. }
        elseif ($3 == check) { r.msg help syntax: .r check [nick (optional)] | r.msg help checks [user] (or you, if no user is given), for $r.chan_chan status }
      }
      if ($2 == invite) { $iif($3,r.invite $nick $3,r.msg error Please give a nickname) }
      elseif ($2 == voice) {
        if ($3) { $iif($r.own($nick),mode $chan +v $3,r.msg error only owners may voice others.) }
        else { mode $cham +v $nick }
      }
      elseif ($2 == check) { r.msg check $iif($3,$3,$nick) currently has $r.check($iif($3,$3,$nick)) chan position }
      elseif ($2 == mode) {
        if ($r.own($nick)) { $iif($3,mode $chan $3-,r.msg error Please us .r mode [arguments]) }
        else { r.msg error this command is limited to owners }
      }
      elseif ($2 == topic) {
        r.dbg topic command by $r.check($nick) $+ : $3-
        if ($r.own($nick)) { $iif($3,r.topic (respect) $3-,r.msg error Please use .r topic [new topic]) }
        else { r.msg error this command is limited to owners. }
      }
      elseif ($2 == add) {
        if ($r.own($nick)) { $iif($3,r.add $nick $3,r.msg error Please use .r add [user]) }
        else { r.msg error this command is limited to owners. }
      }
      elseif ($2 == owner) {
        if ($r.own($nick)) { $iif($3,r.oadd $nick $3,r.msg error Please us .r owner [user]) }
        else { r.msg error this command is limited to owners. }
      }
      elseif ($2 == relay) {
        if ($r.own($nick)) {
          if ($3 == status) { r.msg relay Relay Status: $group(#r.relay) }
          elseif ($3 == on) {
            if ($group(#r.relay) == On) { r.msg error Relay is already on. }
            else { .enable #r.relay | r.msg relay Relay is now On }
          }
          elseif ($3 == off) {
            if ($group(#r.relay) == Off) { r.msg error Relay is already off. }
            else { .disable #r.relay | r.msg relay Relay is now Off. | r.relay status Relay has been disabled by $nick }
          }
          elseif ($3 == setpoint) { set %r.relay $cid | r.msg relay Endpoint set }
        }
        else { r.msg error this command is limited to owners. }
      }
    }
  }
}

; Join Event
on *:JOIN:#: {
  if ($chan !== $r.chan_chan) { halt }
  if ($nick == $me) { halt }
  if ($r.mem($nick)) {
    r.msg entry Welcome, $nick $+ !
    mode $chan +v $nick
    if ($r.own($nick)) { mode $chan +ao $nick $nick }
  }
  else { mode $chan +b $address($nick,4) | kick $chan $nick You are not an authorized user }
}

; Topic Event
on *:TOPIC:#: {
  if ($chan !== $r.chan_chan) { halt }
  if ($nick == $me) { halt }
  r.dbg topic change by $nick $+ . Changing back.
  topic $r.chan_chan %r.topic
}
; Connect event
on *:CONNECT: { join $r.chan_chan }

; Relay
#r.relay off
on ^*:TEXT:*:#: { if ($chan !== $r.chan_chan) { halt } | r.relay $nick $1- }
on ^*:JOIN:#: { if ($chan !== $r.chan_chan) { halt } | r.relay JOIN $nick ( $+ $fulladdress $+ ) }
on ^*:PART:#: { if ($chan !== $r.chan_chan) { halt } | r.relay PART $nick ( $+ $fulladdress $+ ) $iif($1,$+([,$1-,]) }
on ^*:RAWMODE:#: { if ($chan !== $r.chan_chan) { halt } | r.relay MODE $nick - $1- }
on ^*:TOPIC:#: { if ($chan !== $r.chan_chan) { halt } | r.relay TOPIC $nick - $1- }
on ^*:ACTION:#: { if ($chan !== $r.chan_chan) { halt } | r.relay * $nick $1- }
#r.relay end 
