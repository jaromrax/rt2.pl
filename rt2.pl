#!/usr/bin/perl
#
#  I CASE OF 
#                       Can't locate Tk.pm in @INC
#  DO
#      http://hell.org.ua/Docs/oreilly/perl3/tk/index.htm
#  aptitude install perl-tk
#  aptitude install libxml-libxml-perl
###################################
#
# rt2.pl   experimental
#
#  the point is to be able to easily script for different children
#  DICTIONARY
#  it can translate 1/ $runnumber
#                   2/ $outfile
#
#
##################################
use Tk;

use Time::HiRes qw( usleep ualarm gettimeofday tv_interval nanosleep
		      clock_gettime clock_getres clock_nanosleep clock
                      stat );
use XML::LibXML;
#
#   new   nc6   needs  nc6 -q1  to be compatible with nc ???
#       seems to 
#   Listen process must be killed before the STOP!
#
#
# for i in `seq 1 999` ; do  sleep 1; echo $i; done | nc -l 9123
#
# ps -ef | grep nc | grep 3612 | awk  '{ print $2 }'
#
#watch -n 1 'ps -ef | egrep  "(rt.pl|nc)" | grep -v launch | grep -v grep'
#
#

print "######################\n######################\nrt2.pl is still experimental\n######################\n######################\n";

$xmllist=`cd $ENV{'HOME'} ; ls  *.xml`;
$xmllist=~s/\n/ /ig;
print "",$xmllist,"\n";

$FILEXML=`zenity --height 400 --list --column="rt2 configuration" $xmllist`;
print "XML SELECTION: ",$FILEXML,"\n";
if ($FILEXML eq ""){ die "ok, no selection taken, I die\n\n";}
$FILEXML=$ENV{'HOME'}."/$FILEXML";
chop($FILEXML);

##$FILEXML=`zenity --file-selection --file-filter='RT2 CONFIG) | *.xml' --file-filter='All files | *' --directory /home`;
################### RUN programs
#my $nc="nc6 -q1 ";
#   -q0:0    helped to listen,else it reconnected...
my $nc="nc6 -q0:0  ";  # OK
my $nc="nc6 -q0:0 -w 1 "; # LISTEN - 

$nc6exists=`nc6; echo \$?`;
if ($nc6exists==127){
 $nc="nc ";
}
print "nc version == $nc\n";

############# to avoid multiple STOP inc runnumber.....
 $STARTED=0;
################time 
my $date;
my $seconds=0;
my $number="xxx";
my $numberY="xxx";
my $last_seconds=0;
my $last_comment="";
my $last_number="_";


##################### Tk stuff - states of buttons etc..

my @chk_cam=     qw( 0 0 0 0 0 );# maincheckbox !!! Active threads (yes/no)
my @chk_cam_runs=qw( 0 0 0 0 0 );# started--box !!! info about started (yes/no)
my @chk_cam_rt=  qw( 0 0 0 0 0 );#  checkbox !!! this is chkbox: retrig option on/off
my @chk_cam_onstart=qw( 0 0 0 0 0 );#  checkbox !!! : retrig option on/off
my @chk_cam_onstop= qw( 0 0 0 0 0 );#  checkbox !!! : retrig option on/off
#my $autolisten=1;              chk_cam_onstart
#my $autolisten_stop=1;         chk_cam_onstop

my @filepid10_onoff=qw(0 0 0 0 0); # listen state (in file 0 or 1 )

##my @IP=(  "192.168.1.250", "192.168.1.1"  ,   "192.168.1.2"  ,  "192.168.1.3", "192.168.1.6"  );

#my $port_control="9100";
#my $port_dataraw="9301";
#my $port_datauni="9302";

my @PCfname=("PC0_","PC1_","PC2_", "PC3_" , "PC4_" , "PC5_" );


#my $MainXML=$ARGV[0] || "rt2.xml";
my $MainXML;
$MainXML=$FILEXML;
print "MY XML IS     $MainXML    \n\n";
###exit;

my $LOG="startstop.log";
my $online_ext="00000";
my $comment="comment";
my $runnumber=1;

my $entryLog;
my $readoscilo_yn=0;
my $readoscilo_cnt=0;

my $STARTCMD="_GOMON";
my $SETRUNCMD="_RUNUM";
my $STOPCMD ="_STOP";


#######################  cHILren ----###########
my $maxpids=5;  # 5== camac4 is last
my @pid_fname01;     #filename with flag  0/1 to activate child
my $pid_fnameM;     #filename to communicate with Master
my @chk_pidbox;      #initialy - which camac active
###my @start_listen;    # set to 1 to initiate childs
my @listenpid;       #--------------these .. all childrens pids
my @child_start_time; # I try to measure times....

############################HERE IS CONFIG########################XML
 #!/usr/bin/perl

#  use strict;
#  use warnings;
sub get_xml_data{
  my $nn=shift;
  my $what=shift;
  my $tra=shift || "NULL";
  &update_time;
###  my $filename = 'rt2.xml'; 
  my $filename = $MainXML; 

  my $parser = XML::LibXML->new();
  my $doc    = $parser->parse_file($filename);
  my $NT=$doc->findvalue('/prescription/threads');
#  my $AL=$doc->findvalue('/prescription/SFautostart');
#  my $AQ=$doc->findvalue('/prescription/SFautostop');
  my $DT=$doc->findvalue('/prescription/default_t');
  my $ST=$doc->findvalue('/prescription/status_text');
  my $SS=$doc->findvalue('/prescription/status_text_size');

#  print "NUMBER IS $NT / $AL\n\n";
###############  FIRST LEVEL RETURNS ##########################
  if ($what eq "threads"){ return $NT;}
#  if ($what eq "SFautostart"){ return $AL;}
#  if ($what eq "SFautostop"){ return $AQ;}
  if ($what eq "default_t"){ return $DT;}

  if ($what eq "status_text"){ return $ST;}
  if ($what eq "status_text_size"){ return $SS;}



foreach my $thread ($doc->findnodes('/prescription/thread') ){

    #number is important..........
    my $num=$thread->findvalue('./number');
#    my $nam=$thread->findvalue('./name');
#    my $namel=$thread->findvalue('./namel');
#    my $sf_retrig=$thread->findvalue('./spec_function_retrig');
# ---------------commands ---------------------
#    my $lis=$thread->findvalue('./listen');
#    my $cmd=$thread->findvalue('./command');
#    my $cmdi=$thread->findvalue('./init');
#    my $cmdb=$thread->findvalue('./start');
#    my $cmde=$thread->findvalue('./stop');
#    print "   $num. $nam/$lis..... $cmd END\n";

    if ($nn eq $num){
	my $cmd="sleep 0;"; # clear it and have at least one command

	print "DEBUG($nn): $what==".$thread->findvalue($what)."\n";

	if ($what eq "name"){  return $thread->findvalue('./name');}	
	if ($what eq "default_on"){ return $thread->findvalue('./default_on');}	
	if ($what eq "namel"){  return $thread->findvalue('./namel');}
	if ($what eq "spec_function_retrig"){  return $thread->findvalue('./spec_function_retrig');}
	if ($what eq "spec_function_onstart"){  return $thread->findvalue('./spec_function_onstart');}
	if ($what eq "spec_function_onstop"){  return $thread->findvalue('./spec_function_onstop');}


#########COMMANDS ##############
	if ($what eq "on_init")  { $cmd.=$thread->findvalue('./on_init');}
	if ($what eq "on_start") { $cmd.=$thread->findvalue('./on_start');}
	if ($what eq "on_stop")  { $cmd.=$thread->findvalue('./on_stop');}
	if ($what eq "spec_function"){ $cmd.=$thread->findvalue('./spec_function');}
	if ($what eq "quit")  { $cmd.=$thread->findvalue('./quit');}
	if ( $tra eq "translate" ){
	    $cmd.=";"; # better to add ; to be prepared to conditions like .+;

	    $cmd=~s/\$runnumber/$runnumber/ge;  # internal translation
#	    my $rrr="$PCfname[$nn]$online_ext";
	    my $rrr="$PCfname[$nn]$numberY";    #                     
	    $cmd=~s/\$outfile/$rrr/ge;          # internal translation
	    $cmd=~s/\$pidM/$pid_fnameM/ge;            # internal translation

	    $gwd0=`cat GWD_0`; chop($gwd0);
	    $gwd0=~s/\/\/$/\//;   # remove  double // at end
	    $cmd=~s/\$gwd0/$gwd0/ge;                      # internal translation
	    $gwdlocal0=`basename $gwd0`;chop($gwdlocal0);
	    $cmd=~s/\$gwdlocal0/$gwdlocal0/ge;            # internal translation




	    $rrr="";###### special command for stop.
	    if ($cmd=~/\$killgrandchildren/){#############################
		print "XML:$cmd\n";
		if ($chk_cam[$nn]==1){
		print "XML/$nn:$cmd \n";
	    $rrr.=&KILLpid( $nn, "text" ); # only text-out: space delimited 'kill'
#NONONO	    `echo 0 > $pid_fname01[$i]`; # after this death I clear all 9999
	    $rrr.=";";
	    print "...replacing \$killgrandchildren to $rrr\n";
	    $cmd=~s/\$killgrandchildren/$rrr/ge;
		}# if ready to run
		else{
	    $cmd=~s/\$killgrandchildren//ge;
		}
	    }#contains kill directive######################################




	    ##### active command can go from start/stop/quit only
	    $rrr=0;my $rr1;
#	    print "before setstatus text <$cmd>\n";
	    if ($cmd=~/\$setstatustext/){#############################
		print "XML:$cmd\n";
		if ($chk_cam[$nn]==1){
		($rr1,$rrr)=( $cmd=~/\$setstatustext(\ +?)(.+?)\n/ );
		$rrr=~s/;\s*$//;
		print "XML/$nn:$cmd\nLABEL FOUND=<$rrr>\n";
		if ($labelT2!=NULL){##when run from 'spec_function' this doesnot exist.
		$labelT2->configure( -text => $rrr  );
		}else{
		    `echo \`date\` $rrr >> QQQQQQQQQQQ`;
		}
	    $cmd=~s/\$setstatustext(\ +?)(.+)\n//ge;
		}# if ready to run
		else{
	    $cmd=~s/\$setstatustext(\ +?)(.+)\n//ge;  #remove upto ;
		}
	    }#contains text directive######################################
#	    print "after setstatus text\n";


	    # I remove all cummulated spaces, may result in tragedy...?
	    $cmd=~s/\n/ /g;
	    $cmd=~s/\t/ /g;
	    $cmd=~s/     / /g;
	    $cmd=~s/    / /g;
	    $cmd=~s/   / /g;
	    $cmd=~s/  / /g;

	    # when ; ; seen - it makes an error (unexisting kill replace....)
	    $cmd=~s/;\s*;/;/g;$cmd=~s/;\s*;/;/g;$cmd=~s/;\s*;/;/g;
	    $cmd=~s/;\s*;/;/g;$cmd=~s/;\s*;/;/g;$cmd=~s/;\s*;/;/g;
	    $cmd=~s/;\s*;/;/g;$cmd=~s/;\s*;/;/g;$cmd=~s/;\s*;/;/g;


	}
	return $cmd;
    }
}#foreach thread 1..4

 }######################### SUB (XML)
#&get_xml_data(0,"name");
#&get_xml_data(1,"name");
$maxpids2=&get_xml_data(0,"threads");
if ($maxpids2<=$maxpids){ $maxpids=$maxpids2;}
#I removed these two:
#$autolisten=&get_xml_data(0,"SFautostart");
#$autolisten_stop=&get_xml_data(0,"SFautostop");

### -  initial (default) pattern for active crates:
for ($i=0;$i<$maxpids;$i++){
    #individual on   ----  you must check for 0, not to accept the value.....:(
    if (&get_xml_data($i,"default_on")!=0){$chk_cam[$i]=1}
    #individual retrigs
    if (&get_xml_data($i,"spec_function_retrig")!=0){$chk_cam_rt[$i]=1;}
    #individual onstart onstop
    if (&get_xml_data($i,"spec_function_onstart")!=0){$chk_cam_onstart[$i]=1;}
    if (&get_xml_data($i,"spec_function_onstop")!=0){$chk_cam_onstop[$i]=1;}
    print "DEBUG/$i/:  $chk_cam[$i],$chk_cam_rt,$chk_cam_onstart[$i],$chk_cam_onstop[$i]\n";
}




############################HERE IS CONFIG########################XML



#
#  THIS WILL CREATE LOCKS/communication points  in /tmp  $pid_fname01[$i]
#
my $random;
$random=int(rand()*1000);
$pid_fnameM="/tmp/rt2_pid01_".$random."_M";
for($i=0;$i<$maxpids;$i++){
    $pid_fname01[$i]="/tmp/rt2_pid01_".$random."_$i";
    print $pid_fname01[$i], " -  file-switch\n";
    $chk_pidbox[$i]=0;
    $start_listen[$i]=0;#??
    $listenpid[$i]=0;
}


##############################fork here###################### maxpids
# ActivateThread  contains real action....
#
######################
#    we create  child
#     they write 0 to file and then continuously   (while(1==1)) read
#     the file.  If there is "1" in the file => they run ActiveThreat( i )
#     and this will treat orphanism and do
#      NC  addr port > file
#
#  if child == NO pid. If parent => it sees the pid.
#



#1st is all 0
#2nd is 1stnon0 
#
# parent should know about all existing childs. pids: 0 0 0 0
#                                                     1 0 0 0
#                                                     1 1 0 0  etc.
my $zero=1; my $nonzero;

for ($i=0;$i<$maxpids;$i++){
   print "\n\n#$i. test$i  1 means ok\n"; 
   $zero=1;
  for ($j=0;$j<$i;$j++){ #mustnot be 0
      if ($listenpid[$j]==0){$zero=0;} print "$j-A$zero ";
  }# j
  for ($j=$i;$j<$maxpids;$j++){#must be zero
      if ($listenpid[$j]!=0){$zero=0;} print "$j-B$zero ";
  }# j
  if ($zero==1){ 
      print "###################$i. forking $i\n"; 
      unless (defined ($listenpid[$i] = fork)) { die "dying , cannot fork $i: $!";} 
      if ($listenpid[$i]==0){
############################################################################child begin
	  my $iii=$i;
 print "I AM A UNIQUE CHILD  -  see $pid_fname01[$iii]\n";
 `echo 0 > $pid_fname01[$iii]`;
	  ###########################################   CHILD LOOP 
          # every 0.1 seconds READ the file, on change=>activate!
    while (1==1){
	open IN,"$pid_fname01[$iii]";
        my $start_listen=<IN>;chop( $start_listen );close IN;
############# file can contain some information
#   if 1 ..... GO AND RUN (ONLY)
#   if 0 ..... WAIT
#   if 9999 .. also WAIT
##############
	if ($start_listen==1){  ### I had !=0 but maybe 9999 matters
#	    print " prepared to activate threar $iii  \n";
   	    &ActivateThread( $iii );   
#	    print "  after activatethreat $iii \n";
	    `echo 9999 > $pid_fname01[$iii]`; 
        }
	usleep (100* 1000); # 0.1 sec is fine/reasonable
    }#while 1==1
	  ###########################################   CHILD LOOP 

 exit;
############################################################################child end
      }# in the child
  } 
#  print " -> ",$listenpid[$i],"\n";
}# for i=0 < maxpid

print "\n";















##########################################################################
# ##                        MAIN  WINDOW   DESIGN                     ## #
##########################################################################






#MAIN THREAD BEGIN------------------------------------------------##--
$zero=1; for ($i=0;$i<$maxpids;$i++){ if ($listenpid[$i]==0){ $zero=0;}  }
if ($zero==1){
print "inside MAIN:@listenpid  \n";
#MAIN THREAD BEGIN###################################################

my $main = new MainWindow;

########### for balloon HELP: no msgarea for me...#############
$msgarea = $main->Label(-borderwidth => 2, -relief => 'groove');
#$msgarea->pack(-side => 'bottom', fill => 'x');
$ball = $main->Balloon(-statusbar => $msgarea);
##########################################################



my @menubar;
my $i=0;

#   1.      checkboxes
#########################################################################
 $menubar[$i]= $main->Frame(-relief=>"raised",  -borderwidth=>2);

for ($j=0; $j<$maxpids;$j++){
 $txt="Thread$j";   
 $txt=&get_xml_data($j,"name");
 $x_cam[$j] = $menubar[$i]->Checkbutton(-text => "$txt",
                        -variable => \$chk_cam[$j],);
 $x_cam[$j]->pack(-side=>"left", -expand=>0, -padx=>0, -pady=>0);
}#for

 
#--  button na plose ----  menubar2 instead of directly main
$b_q2 = $menubar[$i]->Button(-text=>" QUIT ", -foreground=>"red",-activeforeground=>"red",
   -underline => -1, -command=>\&QUITbutme);
$b_q2->pack(-side=>"right", -expand=>0,    -padx=>0, -pady=>0 );

#---------------------------------------------------###### PACK MENUBAR2
$menubar[$i]->pack(-side=>"top", -expand=>0,
    -padx=>0, -pady=>0, -fill=>"both");
#########################################################################

for ($j=0; $j<$maxpids;$j++){
$ball->attach($x_cam[$j], 
  -balloonmsg => "If checked: the functions defined in rt2.xml will be react when INIT/START/STOP are pressed");
}#j
$ball->attach($b_q2, -balloonmsg => "QUIT with this buttons, else there remain children running in background");


$i++;
#   2.         start stop buttons
#########################################################################
 $menubar[$i]= $main->Frame(-relief=>"raised",  -borderwidth=>2);

#--  button na plose ----  menubar2 instead of directly main
$b_gomoni = $menubar[$i]->Button(-text=>"  INIT  ",
   -underline => -1, -command=>\&INITbut);
$b_gomoni->pack(-side=>"left", -expand=>0,    -padx=>0, -pady=>0 );


#--  button na plose ----  menubar2 instead of directly main
$b_gomon = $menubar[$i]->Button(-text=>"  START  ",
   -underline => -1, -command=>\&STARTbut);
$b_gomon->pack(-side=>"left", -expand=>0,    -padx=>0, -pady=>0 );


#--  button na plose ----  menubar2 instead of directly main
$b_stop = $menubar[$i]->Button(-text=>"  STOP  ",
   -underline => -1, -command=>\&STOPbut);
$b_stop->pack(-side=>"left", -expand=>0,    -padx=>0, -pady=>0 );

   $b_gomoni->configure(-background=>'yellow',-activebackground =>'yellow' );
   $b_gomon->configure(-background=>'darkgray',-activebackground =>'darkgray' );
   $b_stop->configure(-background=>'darkgray',-activebackground =>'darkgray' );


###--  button na plose ----  menubar2 instead of directly main
#$b_q = $menubar[$i]->Button(-text=>"q",
#   -underline => -1, -command=>\&Qbut);
#$b_q->pack(-side=>"left", -expand=>0,    -padx=>0, -pady=>0 );



#--  button na plose ----  menubar2 instead of directly main
$b_q2 = $menubar[$i]->Button(-text=>" QUIT ", -foreground=>"red", -activeforeground=>"red",
   -underline => -1, -command=>\&QUITbutme);
$b_q2->pack(-side=>"right", -expand=>0,    -padx=>0, -pady=>0 );

##--  button na plose ----  menubar2 instead of directly main
#$b_oscilo = $menubar[$i]->Button(-text=>"Osciloscope", -foreground=>"darkblue", -activeforeground=>"darkgreen",
#   -underline => 0, -command=>\&OSCILObut);
#$b_oscilo->pack(-side=>"right", -expand=>0,    -padx=>0, -pady=>0 );

#$b_oscilo->repeat( 10000, \&READoscilo   );


$ball->attach($b_gomoni, 
  -balloonmsg => "INIT button: it runs initial scripts - if necessary - defined in  rt2.xml");
$ball->attach($b_gomon, 
  -balloonmsg => "START: send a command to START the process; if green == run is running");
$ball->attach($b_stop, 
  -balloonmsg => "STOP: send a command to STOP the process; if red == run is stopped");
$ball->attach($b_q2, 
  -balloonmsg => "QUIT: the same as above - use these buttons to QUIT");



#---------------------------------------------------###### PACK MENUBAR2
$menubar[$i]->pack(-side=>"top", -expand=>0,
    -padx=>0, -pady=>0, -fill=>"both");




#####sub changed{    print "$_[0] changed\n";}
$i++;
#   3.         comment
#########################################################################
 $menubar[$i]= $main->Frame(-relief=>"flat",  -borderwidth=>2, -background=>'black', -foreground=>'white');

# ---------- entry field
$entry= $menubar[$i]->Entry(-text => "textEntry", -textvariable => \$comment,
 -background=>'black', -foreground=>'white',
 -validate         => 'key',
 -validatecommand  => sub{&update_time;$last_comment=$date;} );
# Set to expand, with padding.
$entry->pack(-side=>"left", -expand=>1, -fill=>"x", -ipadx=>0, -padx=>0, -pady=>1);
##$entry->bind('<<Modified>>',sub{print shift," COMMENT changed\n"});

#$entry->bind('<Modified>'=>sub {
#        if($entry->editModified() ) {$entry->editModified(0) }
#    });

############# arabic way from right
# ---------- entry field RUN NUM
$entryRN= $menubar[$i]->Entry(-text => "textEntry", -textvariable => \$runnumber, -width=>5, -background=>'cyan', -foreground=>'black', -font=>'bold');
# 
$entryRN->pack(-side=>"right", -expand=>0, -ipadx=>20, -padx=>0, -pady=>0);
# ---------- entry field RUN NUM
$labelRN= $menubar[$i]->Label(-text => "RUN #",  -background=>'black', -foreground=>'cyan');
# 
$labelRN->pack(-side=>"right", -expand=>0, -ipadx=>0, -padx=>0, -pady=>0);



#---------------------------------------------------###### PACK MENUBAR2
$menubar[$i]->pack(-side=>"top", -expand=>0,
    -padx=>0, -pady=>0, -fill=>"both");






$ball->attach($entry, 
  -balloonmsg => " put a commentary here, it will be stored in LOG file.");
$ball->attach($labelRN, 
  -balloonmsg => "run number, you can edit");
$ball->attach($entryRN, 
  -balloonmsg => "run number, you can edit");





$i++;
#   4.            listen buttons
#########################################################################
 $menubar[$i]= $main->Frame(-relief=>"raised",  -borderwidth=>2);


# ---------- entry field RUN NUM
$labelLTline= $menubar[$i]->Label(-text => "SpecialFunction: ");
$labelLTline->pack(-side=>"left", -expand=>0, -ipadx=>10, -padx=>0, -pady=>0);



for ($j=0; $j<$maxpids;$j++){
 $txt="Listen $j";   
 $txt=&get_xml_data($j,"namel"); # name listen

$b_list[$j] = $menubar[$i]->Button(-text=>"$txt",
   -underline => -1, -command=>[\&Listenbut,$j] );
$b_list[$j]->pack(-side=>"left", -expand=>0,    -padx=>0, -pady=>0 );
}#for




# $alis = $menubar[$i]->Checkbutton(-text => "Launch On Start",
#                        -variable => \$autolisten,);
# $alis->pack(-side=>"left", -expand=>0, -padx=>0, -pady=>0);
# $alise = $menubar[$i]->Checkbutton(-text => "Kill On Stop",
#                        -variable => \$autolisten_stop,);
# $alise->pack(-side=>"left", -expand=>0, -padx=>0, -pady=>0);


 $txt="StartAll S.F.";   
##   WE HAVE A TIMER HERE    was  1sec,  now it is 0.1 sec. check
$b_list0 = $menubar[$i]->Button(-text=>"$txt",
   -underline => -1, -command=>[\&Listenbut,-1] );
$b_list0->pack(-side=>"right", -expand=>0,    -padx=>0, -pady=>0 );
#$b_list0->repeat( 1000, \&ChkState   );
$b_list0->repeat( 100, \&ChkState   );



# $alis2 = $menubar[$i]->Checkbutton(-text => "AutoRetrig_Func",
#                        -variable => \$autolisten2,);
# $alis2->pack(-side=>"left", -expand=>0, -padx=>0, -pady=>0);
#---------------------------------------------------###### PACK MENUBAR2
$menubar[$i]->pack(-side=>"top", -expand=>0,
    -padx=>0, -pady=>0, -fill=>"both");



for ($j=0; $j<$maxpids;$j++){
$ball->attach($b_list[$j], 
  -balloonmsg => "Special Function == each button has EXTRA SCRIPT, label and meaning of each is defined in rt2.xml");
}#j
$ball->attach($b_list0, 
  -balloonmsg => "RUN all Special Functions (extra scripts) NOW - without using START button");




$i++;
#   1b.      checkboxes
#########################################################################
 $menubar[$i]= $main->Frame(-relief=>"raised",  -borderwidth=>2);

# ---------- entry field RUN NUM
$labelOnStart= $menubar[$i]->Label(-text => "LaunchOnStart : ");
$labelOnStart->pack(-side=>"left", -expand=>0, -ipadx=>10, -padx=>0, -pady=>0);


for ($j=0; $j<$maxpids;$j++){
 $txt="Thread$j";   
 $txt=&get_xml_data($j,"namel");
# $txt="$txt";   
 $x_cam_onstart[$j] = $menubar[$i]->Checkbutton(-text => "$txt",
                        -variable => \$chk_cam_onstart[$j],);
 $x_cam_onstart[$j]->pack(-side=>"left", -expand=>0, -padx=>0, -pady=>0);
}#for

#---------------------------------------------------###### PACK MENUBAR2
$menubar[$i]->pack(-side=>"top", -expand=>0,
    -padx=>0, -pady=>0, -fill=>"both");
#########################################################################



for ($j=0; $j<$maxpids;$j++){
$ball->attach($x_cam_onstart[$j], 
  -balloonmsg => " If checked : on START button - the Special Function will be auto-launched");
}#j




$i++;
#   1b.      checkboxes
#########################################################################
 $menubar[$i]= $main->Frame(-relief=>"raised",  -borderwidth=>2);

# ---------- entry field RUN NUM
$labelOnStop= $menubar[$i]->Label(-text => "     Kill   On Stop : ");
$labelOnStop->pack(-side=>"left", -expand=>0, -ipadx=>10, -padx=>0, -pady=>0);


for ($j=0; $j<$maxpids;$j++){
 $txt="Thread$j";   
 $txt=&get_xml_data($j,"namel");
# $txt="$txt";   
 $x_cam_onstop[$j] = $menubar[$i]->Checkbutton(-text => "$txt",
                        -variable => \$chk_cam_onstop[$j],);
 $x_cam_onstop[$j]->pack(-side=>"left", -expand=>0, -padx=>0, -pady=>0);
}#for

#---------------------------------------------------###### PACK MENUBAR2
$menubar[$i]->pack(-side=>"top", -expand=>0,
    -padx=>0, -pady=>0, -fill=>"both");
#########################################################################



for ($j=0; $j<$maxpids;$j++){
$ball->attach($x_cam_onstop[$j], 
  -balloonmsg => " If checked : on STOP button - the Special Function will be auto-stopped");
}#j





$i++;
#   1b.      checkboxes - retrig each channel extra 
#########################################################################
 $menubar[$i]= $main->Frame(-relief=>"raised",  -borderwidth=>2);

# ---------- entry field RUN NUM
$labelRTline= $menubar[$i]->Label(-text => "AutoReTrig S.F. : ");
$labelRTline->pack(-side=>"left", -expand=>0, -ipadx=>10, -padx=>0, -pady=>0);


for ($j=0; $j<$maxpids;$j++){
 $txt="Thread$j";   
 $txt=&get_xml_data($j,"namel");
# $txt="$txt";   
 $x_cam_rt[$j] = $menubar[$i]->Checkbutton(-text => "$txt",
                        -variable => \$chk_cam_rt[$j],);
 $x_cam_rt[$j]->pack(-side=>"left", -expand=>0, -padx=>0, -pady=>0);
}#for

#  $alis2 = $menubar[$i]->Checkbutton(-text => "AutoRetrig_ALL",
#                        -variable => \$autolisten2,);
# $alis2->pack(-side=>"left", -expand=>0, -padx=>0, -pady=>0);

#---------------------------------------------------###### PACK MENUBAR2
$menubar[$i]->pack(-side=>"top", -expand=>0,
    -padx=>0, -pady=>0, -fill=>"both");
#########################################################################






for ($j=0; $j<$maxpids;$j++){
$ball->attach($x_cam_rt[$j], 
  -balloonmsg => " If checked : after Special Function command ends by itself, it will be RELAUNCHED again");
}#j





$i++;
#   5.            TEXT LOG
#########################################################################
 $menubar[$i]= $main->Frame(-relief=>"raised",   -borderwidth=>2);

# I want it expanding .... and I have it == -fill=>"both" at pack !!!
#$entryLog= $menubar[$i]->Scrolled("Text", -scrollbars=>'oe',  -height => 10 );
$entryLog= $menubar[$i]->Scrolled("Text", -scrollbars=>'oe' );
#$entryLog->pack(-side=>"right", -expand=>1,  -padx=>0, -pady=>0);
$entryLog->pack( -expand=>1,  -padx=>1, -pady=>1, -fill=>"both");

#---------------------------------------------------###### PACK MENUBAR2
$menubar[$i]->pack(-side=>"top", -expand=>1,
    -padx=>0, -pady=>0, -fill=>"both");







my $TEXYT=&get_xml_data(0,"status_text");
if (&get_xml_data(0,"status_text_size")==0){ $TEXYT="";}
if ($TEXYT ne ""){
$i++;
#   6.            TEXYT   status text   line
#########################################################################
 $menubar[$i]= $main->Frame(-relief=>"raised",   -borderwidth=>2);

my $font = $main->fontCreate(    -size => &get_xml_data(0,"status_text_size"),
                                 -weight => 'bold');

$labelT1= $menubar[$i]->Label(-text => "    ", -font=> $font );
$labelT1->pack(-side=>"left", -expand=>0, -ipadx=>10, -padx=>0, -pady=>0 );
$labelT2= $menubar[$i]->Label(-text => &get_xml_data(0,"status_text"), -font=> $font );
$labelT2->pack(-side=>"left", -expand=>0, -ipadx=>10, -padx=>0, -pady=>0 );
#---------------------------------------------------###### PACK MENUBAR2
$menubar[$i]->pack(-side=>"top", -expand=>0,
    -padx=>0, -pady=>0, -fill=>"both");
}






#my $c = $main->Canvas(-width => 660, -height => 480);
#$c->pack;

MainLoop;
##################################################################MAINLOOP

#MAIN THREAD ENDS###################################################
}else{ print "some orphan dies\n"; exit;}
#MAIN THREAD )if zero==1 => all childs are nonzero.....


exit;











#########################################################################
#         GENERAL PROCEDURES -------------------------- 
#########################################################################



sub update_time{
#  $t0 = [gettimeofday];

#   $last_seconds=$seconds;

  ($seconds, $microseconds) = gettimeofday;
  $microseconds=sprintf "%06d",$microseconds;
  $microseconds=substr($microseconds,0,2);

   $seconds=$seconds+$microseconds/1000. ;

  $number=`date +%y%m%d_%H%M%S`; 
  $numberY=`date +%Y%m%d_%H%M%S`; 
  chop( $number );
  chop( $numberY );
  $date=`date "+%d/%m/%Y %H:%M:%S"`; 
  chop( $date );
$date=$date.".$microseconds";
 # $entryLog->insert('1.0',"$seconds    $number   $date\n");
}



sub Log{
   my $txt=shift; 
   my $auxi=shift || 0;
   my $logaux=$LOG.".aux";

   &update_time;
   my $stamp="$date - $txt\n";
   if (defined $entryLog){
       if ($auxi!=1){
	   $entryLog->insert('1.0',"$stamp");
       }
   }
  print "$stamp";
   if ($auxi==1){
       open LOG,">>$LOG.aux";
   }else{
       open LOG,">>$LOG";
   }
   print LOG "$stamp";
   close LOG;
}#Log










# every 1000 ms
##################################################
# ChkState - light green the button if we Listen #
#
#   we can use for backward communication.....for status_text
  ##################################################
sub ChkState{
   &update_time;

# this message system is completely independent on thread, start/stop
		open IN2,"$pid_fnameM" ; $pidM=<IN2>;chop( $pidM );close IN2;
		if ( $pidM ne ""){#....if there is a message
		    `rm $pid_fnameM`;
		    #print "      getting <$pidM> message to labelT2 from $pid_fnameM\n";
		    $labelT2->configure( -text => $pidM   );
		}#there is a message...


#########just colors############
	 $b_list0->configure(-background=>'darkgray',-activebackground =>'darkgray' );
  for ($i=0;$i<$maxpids;$i++){
	    if ($chk_cam[$i]==1){
	 $b_list[$i]->configure(-background=>'white',-activebackground =>'white' );
	 $b_list0->configure(-background=>'white',-activebackground =>'white' );
	    }else{
	 $b_list[$i]->configure(-background=>'darkgray',-activebackground =>'darkgray' );
	    }	 
  }


  for ($i=0;$i<$maxpids;$i++){
  	    if ($chk_cam[$i]==1){#global chk_cam.......simplify...deal only when checkbox

    open IN,"$pid_fname01[$i]" ;
      my $start_listen=<IN>;chop( $start_listen );
      close IN;
      $filepid10_onoff[$i]=$start_listen;
	if ($start_listen==1){
	 $b_list[$i]->configure(-background=>'green',-activebackground =>'green' ); 
	}else{ # means if 0 or even 9999. 9999== ended by itself

	    if ( ($start_listen==9999)){ #announce. This is to display an anouncement
		if ($child_start_time[$i]>0) {
		my $delta= $seconds-$child_start_time[$i]; $delta=sprintf "%.3f", $delta;
		$child_start_time[$i]=0;
         	&Log("S.Func# [$i] OFF ... was found OFF ... $delta sec.",1);  
		}# time>0 ### it has 9999 every kill/stop, but time>0 only when stop
#        	&Log( "   #ActiveThread :      #Client was stopped $j        ");
		`echo 0 > $pid_fname01[$i]`; 
	    }#9999 ==> announce it as found in OFF

	}#end of  means if 0 or even 9999



###########################
#bordel
#   autolisten2 --- retrig all REPLACED BY chk_cam_onstart
#   $chk_cam_runs[$i]  --- use only when started (good to keep with launchOnStart)
#
##########################
### when autolisten2 == 1 : reconnect automaticaly
### or when separate checkbutton && allowed.....reconnect automat
#REMOVED      if ( $chk_cam_runs[$i] != 0 ){###this results in (autolisten) when started only!
   if (  ($chk_cam_runs[$i]!=0)&&($chk_cam_onstart[$i]==1) ){###this results in (autolisten) when started only!

###########  20130531-vidim, ze se Log nesmyslne opakuje, musim dat jeste jednu podminku: zkusim pid==0
   open IN,"$pid_fname01[$i]"; my $tstX=<IN>;chop( $tstX );close IN;
   if (  
	  (($chk_cam_rt[$i]==1)&& ($chk_cam[$i]==1) && ($tstX==0) )
)  {
#?       if ($start_listen!=1){
        `echo 1 > $pid_fname01[$i]`; 
	$child_start_time[$i]=$seconds ;
	 &Log("S.Func# $i ON ... by AutoRetrig ",1); 
#       }# retrig only when it is not ON
   }# autolisten2 - auto reconnect.....>????????
#REMOVED      }#### $chk_cam_runs[$i] != 0 ### start was pressed before
   }
       #### this results in (autolisten) when started only!

	    }#global chk_cam.............simplify...deal only when checkbox
  }#for  i
}#ChkState







###############################
# normaly, at the launch time, $t is taken from file in /tmp
#
# My intention here is to prepare a parser 
#   that would take a batch line by line and 
#   every line he would do &Log(.....),
#   maybe shell is ok for this???
# I have also a number that can be transfered by the /tmp/file....
#
# That means a config file (xml?): section/name-> displays in top
#                                  extra(listen)button name
#                                  commands on click start/ stop / listen
#
###############################
sub ActivateThread(){
    my $j=shift;
#   $t  comes from the file $pid_fname01[$par]??NO - it is number of the thread!
# i dont remember why this.....

    &Log( "   #ActiveThread :     #Starting client [$j]           ",1);
    my $cmdline=get_xml_data( $j, "spec_function" , "translate" );
    &Log( "   issuing S.F. activate to device [$j]: <$cmdline>",1);

    system("bash -c \"$cmdline\" ");

    &Log( "   #Stopping client [$j] #leaving ActiveThread # ...",1);
}#Activate Thread














#########################################################################
#         BUTTONS -------------------------- BUTTONS
#########################################################################

sub INITbut{
    my $immedstop=0;
    &Log( "INIT#############################################\n           $comment" );
    $b_gomon->configure(-background=>'lightgrey',-activebackground =>'lightgrey');
    $b_stop->configure(-background=>'lightgrey',-activebackground =>'lightgrey');
    $b_gomoni->configure(-background=>'lightgrey',-activebackground =>'lightgrey' );
    $last_seconds=$seconds;  $last_number=$number;
 for ($j=0;$j<$maxpids;$j++){ 
  if ($chk_cam[$j]==1){
       my $cmdline=get_xml_data( $j, "on_init" , "translate" );
       &Log( "   issuing   init to device [$j]: <$cmdline>");
       system("bash -c \"$cmdline\" ");
#
 #      print `bash -c \"$cmdline\"`;
#      `echo $SETRUNCMD $runnumber | $nc $IP[$j]  $port_control ` ;
       if ($?!=0){   
	   &Log( "      NOT SUCCESFULL !!!!!!!!!!!!!!"); 
	   $b_gomon->configure(-background=>'yellow',-activebackground =>'yellow');
	   $b_stop->configure(-background=>'yellow',-activebackground =>'yellow');
	   $b_gomoni->configure(-background=>'yellow',-activebackground =>'yellow' );
	   return;
       }
      &Log( "      finished   init to device [$j]");
  }
 }
#NOT HERE    if ($autolisten==1){    &Listenbut(-1);}


    $b_gomoni->configure(-background=>'blue',-activebackground =>'blue' );
    $b_gomon->configure(-background=>'white',-activebackground =>'white' );
#    $b_stop->configure(-background=>'red',-activebackground =>'red');
    $b_stop->configure(-background=>'red',-activebackground =>'red');

#    for ($j=0; $j<$maxpids;$j++){
#	$b_list[$j]->configure(-background=>'white',-activebackground =>'white' );
#    }#for


# access to checkboxes etc...
#    for ($i=0;$i<$maxpids;$i++){print "   Thread_$i:$chk_cam[$i] "; }print "\n";

}#INIT..........................................



sub STARTbut{
    my $immedstop=0;
#    &Log( "START#############################################\n$last_comment  $comment" );
    &Log( "START#############################################\nRUN $runnumber\n$last_comment  $comment" );
    #SPECIAL TIME FOR LAST CHANGE IN COMMENT!  $last_comment
    $last_seconds=$seconds;  $last_number=$number;

############ $labelT2->configure( -text => ""  );### we can change the status text

 for ($j=0;$j<$maxpids;$j++){ 
  if ($chk_cam[$j]==1){
       my $cmdline=get_xml_data( $j, "on_start" , "translate" );
      &Log( "   issuing  start to device [$j]: <$cmdline>");
       system("bash -c \"$cmdline\" ");
#       print `bash -c \"$cmdline\"`;

       $chk_cam_runs[$j]=0;# it runs (no)
       if ($?!=0){   
	   &Log( "      NOT SUCCESFULL !!!!!!!!!!!!!!"); 
           $b_gomon->configure(-background=>'yellow',-activebackground =>'yellow');
	   $b_stop->configure(-background=>'yellow',-activebackground =>'yellow');
	   $b_gomoni->configure(-background=>'yellow',-activebackground =>'yellow' );
	   return;
       }
       $chk_cam_runs[$j]=1; #it runs (yes)
      &Log( "      finished  start to device [$j]");

    if ($chk_cam_onstart[$j]==1){  
	if ($filepid10_onoff[$par]==0){#not running 
	&Listenbut( $j );
	}else{
	     my $delta= $seconds-$child_start_time[$par]; $delta=sprintf "%.3f", $delta;
	    &Log("S.Func# $par is already running for           ... $delta sec.",1); 
	}
    }# is On_start => means start it.

  }#$chk_cam[$j]==1 .....  this thread was active
 }#all pids  ...... one by one


    $b_gomon->configure(-background=>'green',-activebackground =>'green' );
#    $b_stop->configure(-background=>'red',-activebackground =>'red');
#    $b_stop->configure(-background=>'grey',-activebackground =>'grey');
    $b_stop->configure(-background=>'white',-activebackground =>'white');

# access to checkboxes etc...
#    for ($i=0;$i<$maxpids;$i++){print "   Thread_$i:$chk_cam[$i] "; }print "\n";
    $STARTED=1;
}#STARTBUT GOMON..........................................






############################################
# Listenbut       - if the button is pressed - set the file  #
############################################
#    launches  LISTEN childrens by switching the file value
#    I call it Fun now (function)
#
sub Listenbut{
   my $par=shift;
     #&Log( "Listen Button $par pressed" );

     if ($par<0){# recurse
	 for ($j=0;$j<$maxpids;$j++){ if ($chk_cam[$j]==1){&Listenbut($j);} }
     }else{# if 1 the stop, if 0 then start
	  if ($chk_cam[$par]==1){
	 if ($filepid10_onoff[$par]==0){	
	     $child_start_time[$par]=$seconds ;
	   &Log("S.Func# $par ON <".&get_xml_data($par,"namel").">" ,1); `echo 1 > $pid_fname01[$par]`;
	   #in fact, this flag will trig  sub ActivateThread(){ !!!
	 }else{	
############this part is here onlny because of flip character of the listenbutton!!!	
       #	   `echo 0 > $pid_fname01[$par]`;  
	   # newly  NOKILL &KILLpid( $par); 
	   `echo 0 > $pid_fname01[$par]`;  # doesnot really overwrite 9999
	   &KILLpid( $par); ### If I don do kill, I cannot really OFF!!! 
	     my $delta= $seconds-$child_start_time[$par]; $delta=sprintf "%.3f", $delta;
	   &Log("S.Func# $par OFF                              ... $delta sec.",1); 
	   # killing takes time..... we cannot be too precise......
	   $child_start_time[$par]=0;
#####	     &Log("S.Func# $par is already running for           ... $delta sec."); 
	 }
	  }#aplicable
}#par>=0
}#ListenBut




#  run,kill - easy for nc ..
#  run,kill2 - hard for sh -c nc ... which appears with PIPE
#
# KILLpid 1234 "text" ==>> makes text...
sub KILLpid{
    my $i=shift;  
    my $mode=shift || "none";
#    print "KILL$i:MODE = $mode\n";
    my $run;my $kill;my $kill2;

    if ($chk_cam[$i]==1){
#	print "KILL$i:my name is $0 and listenpid(child pid) for $i is  $listenpid[$i] \n";
# I search for the grandchild, ... that I kill
	print `ps -ef | grep -v grep | grep $listenpid[$i] `;
#	print "CHILDERN: \n";
#	print `ps -ef | grep -v grep | grep $listenpid[$i] | grep -v $0`;
# just to be sure I kill opened shell 
#	print `ps -ef | grep -v grep | grep $listenpid[$i] | grep -v $0 | grep sh `;
	my $grandchild=`ps -ef | grep -v grep | grep $listenpid[$i] | grep -v $0 | grep "sh -c" | awk  '{ print \$2 }'`;
	chop($grandchild);
#	print "...killing grandchild...$grandchild\n";
	if ($grandchild ne ""){ 

######http://stackoverflow.com/questions/392022/best-way-to-kill-all-child-processes
	    my $listkill= `pstree -p $grandchild`; 
	    print "KILL[$i]: LISTKILL  == $listkill\n";
#	    print "LISTKILL  == $listkill : @listkill\n";
#	    $listkill.=" $grandchild  ";
	    my @listkill= (`pstree -p $grandchild` =~ m/\((\d+)\)/sg);
#	    print "KILL$i:LISTKILL  == @listkill\n";
	    if ($mode eq "text"){
                &Log( "   #sending info [$i] on kill              @listkill");
#		print "KILL:Only text is output:  <kill @listkill>\n";
		return "kill @listkill";
	    }else{
            &Log( "   #killing[$i] $grandchild and @listkill");
	    kill 15, (`pstree -p $grandchild` =~ m/\((\d+)\)/sg); 
#	    kill( 15, $grandchild ); 
	    }
	}
    }
    return;
##########################################################################
     if ($chk_cam[$i]==1){
#       &Log( "   #searching for kill $i...");
    `echo 0 > $pid_fname01[$i]`;
     $run="ps -ef | grep nc | grep -v grep |  grep $listenpid[$i] | awk  '{ print \$2 }'";
     $rut="ps -ef | grep nc | grep -v grep |  grep $listenpid[$i] ";
     $kill=`$run`; chop( $kill );#get PID of nc program whose parent is our child
     $kitt=`$rut`; chop( $kitt );#get PID of nc program whose parent is our child
#     now I can have sh -c  nc ...... > file
    if ($kitt=~/sh/){
     $run="ps -ef | grep nc | grep -v grep | grep $kill | grep -v sh | awk  '{ print \$2 }'";
     $kill2=`$run`; chop( $kill2 );	
    }
     if ($kill2>0){&Log( "   #killing sh $kill2 now");  kill( 15, $kill2 ); }
     if ($kill >0){&Log( "   #killing    $kill now");  kill( 15, $kill ); }
#     if ($kill2>0){&Log( "   #killing $kill2 now");  kill( 15, $kill2 ); }
     
   }# checkbox ==1 
}#KILLpid


#
# not working.....
#
sub Qbut{
        &Log( "q  #############################################" );
  for ($j=0;$j<$maxpids;$j++){ 
  if ($chk_cam[$j]==1){
       my $cmdline=get_xml_data( $j, "quit" , "translate" );
       &Log( "   issuing   quit to device [$j]: <$cmdline>");
       system("bash -c \"$cmdline\" ");
#       print `bash -c \"$cmdline\"`;

  }
  `rm $pid_fname01[$j]`;
  }
}#Qbut






sub STOPbut{
     &Log( "STOP#############################################" );
     my $t=($seconds-$last_seconds); $t=sprintf "%.3f", $t;
     if ($last_seconds!=0){
       &Log( "$t seconds length to this point " );
     }else{
       &Log( "$t seconds length to this point BUT NO START pressed " );
     }
    &Log( "waiting to finish kills, sleep 0 seconds");

 for ($j=0;$j<$maxpids;$j++){ 
  if ($chk_cam[$j]==1){# thread is active
       my $cmdline=get_xml_data( $j, "on_stop" , "translate" );
      &Log( "   issuing   stop to device [$j]: <$cmdline>");

       # there could be also killgrandchildren command inside
       # but preferably I use rather KillOnStop now......
       system("bash -c \"$cmdline\" ");
       print "    KILLING?? BECAUSE chk_cam_onstop==($chk_cam_onstop[$j]) \n";
       if ($chk_cam_onstop[$j]==1){
           print "    KILLING !! BECAUSE (chk_cam_onstop[j]==1\n";

	   $chk_cam_runs[$j]=0;`echo 0 > $pid_fname01[$j]`; # force to stop
	   &KILLpid( $j); 
	   $chk_cam_runs[$j]=0;`echo 0 > $pid_fname01[$j]`; # force to stop
       }else{
	   print "    NOT KILLING BECAUSE chk_cam_onstop[j]==0\n";
       }

       if ($?!=0){   
	   &Log( "      NOT SUCCESFULL !!!!!!!!!!!!!!"); 
	   $b_gomon->configure(-background=>'yellow',-activebackground =>'yellow');
	   $b_stop->configure(-background=>'yellow',-activebackground =>'yellow');
	   $b_gomoni->configure(-background=>'yellow',-activebackground =>'yellow' );
	   return;
       }
       $chk_cam_runs[$j]=0;# it runs (no)
      &Log( "   finished  stop to device [$j]");
  }
 }

     my $t=($seconds-$last_seconds); $t=sprintf "%.3f", $t;
     &Log( "STOPPED##########################################" );
#     &Log( "$t seconds length" );
     if ($last_seconds!=0){
       &Log( "$t seconds length  " );
     }else{
       &Log( "$t seconds length BUT NO START pressed " );
     }

    $b_gomon->configure(-background=>'white',-activebackground =>'white' );
    $b_stop->configure(-background=>'red',-activebackground =>'red');

     if ( $STARTED == 1){
	 $runnumber++;
     }
     $STARTED=0;
}#STOP.............................................................









sub READoscilo{
    if ($readoscilo_yn==1){
   # &Log( "READ Oscilscope########################################" );
  &update_time;#
#  `wget --tries=1  http://192.168.1.177/Image.png -O `date +%Y%m%d-%H%M%S.png`;
 `wget --tries=1  http://192.168.1.177/Image.png -O oscilo_$numberY.png ` ;
  $readoscilo_cnt++;
  if ($readoscilo_cnt>359){
     &Log( "tar  Osciloscope  ######################################" );
     `tar -cf oscilo_$numberY.tar  oscilo_2*.png;  rm oscilo_2*.png`;
     &Log( "rm oscilo_2*.png  ######################################" );
      $readoscilo_cnt=0;
  }#359 (1 hour)
    }#yn == 1
}#sub  readoscilo



sub OSCILObut{
#        &update_time;
  if ( $readoscilo_yn==1 ){ 
    &Log( "Osciloscope OFF  ######################################" );
      $readoscilo_yn=0;
  $b_oscilo->configure(-background=>'gray',-activebackground =>'gray' );
  }else{ 
    &Log( "Osciloscope ON  #######################################" );
    $b_oscilo->configure(-background=>'green',-activebackground =>'green' );
    $readoscilo_yn=1;   
  }
    #$b_gomon->configure(-background=>'gray',-activebackground =>'gray' );
    #$b_stop->configure(-background=>'gray',-activebackground =>'gray');

  #no   exit;
}#OSCILO........................................................





sub QUITbutme{
#        &update_time;
    &Log( "QUIT#############################################" );
    &Qbut;
    $b_gomon->configure(-background=>'gray',-activebackground =>'gray' );
    $b_stop->configure(-background=>'gray',-activebackground =>'gray');

#
#  this is the way to sopt other threads......
#

##this KILLS ALL LXDE !!!!!!!!!
#   kill( 15, 0 );



#    waitpid($listenpid3,0);
#    waitpid($listenpid2,0);    
#    waitpid($listenpid1,0); 

#for(my $i=0;$i<$maxpids;$i++){
for(my $i=$maxpids-1;$i>=0;$i--){
    kill( 15,$listenpid[$i] );
    `rm $pid_fname01[$i]`;
    
}   

# last resort - works -maybe
#   `killall rt2.pl`;
exit;

}#QUIT........................................................



