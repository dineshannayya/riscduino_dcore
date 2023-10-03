#!/usr/bin/perl -w
#------------------------------------------------------------------------
# Declarations
#------------------------------------------------------------------------
use Getopt::Long;
use File::Basename;
use FileHandle;
use Cwd;
use strict;

#------------------------------------------------------------------------
# subroutine declarations -
#------------------------------------------------------------------------
sub parse_options;
sub die_usage;

#------------------------------------------------------------------------
# variable declarations -
#------------------------------------------------------------------------
my ($help, $file_list) ;
my $run_dir = "";
my $simv_dir = "./";
my $tests_list = "";
my $parse_testlogs = 0;
my $testlog_name = "";
my $parse_options = "all";
my $cur_dir = cwd();
my $log_name = "";
my $tst_stats = "";

#map {print "$_:\n" } @ARGV;
#print STDERR (join("|",@ARGV),"\n");
# ---------------
# Main Program
# ---------------
&s_parse_options;
&parse_logfile;


#------------------------------------------------------------------------------
# SUBROUTINE: parse_logfile
#------------------------------------------------------------------------------
sub parse_logfile{
  my $file_name = "$simv_dir/$tests_list";
  my $TESTS_H = new FileHandle;
  my $GENLISTS = new FileHandle;
  my $test_status = "";
  my $tests_line = "";
  my $test_name = "";
  my $test_domain = "";
  my $testcase_dir = "";
  my $sim_time = "";
  my @test_args = ();
  my $total_testcases = 0;
  my $total_pass = 0;
  my $total_fail = 0;
  my $total_unk = 0;
  my $args_index = 0;
  my $test_arg = "";
  my $test_config = "";
  my $display_stat = 1;
  my $n_warns = 0;
  my $n_errors = 0;

  &check_tests_list;
  &check_run_dir;

  $~ = 'STATUS_HEADER';
  write();

  open($TESTS_H,"<$file_name") || die "couldn't open $file_name";
  while ($tests_line = <$TESTS_H>) {
   if ($tests_line !~ /^\/|^#|^\s+/) { # if line not commented
     chomp($tests_line);
     #($test_name,$testcase_dir) = split(/,/,$tests_line);
     my @test_data = split(/,/,$tests_line);
     $test_domain = $test_data[0];
     $test_name = $test_data[1];
     $testcase_dir = $test_data[2];
     #$testcase_dir = $test_name;
     &parse_testlog("$test_name","$run_dir/$testcase_dir/$testlog_name",\$test_status,\$sim_time,\$n_warns,\$n_errors);
     $test_config = "";
     $test_config = `cat $run_dir/$testcase_dir/tc_config` if (-e "$run_dir/$testcase_dir/tc_config");
     $total_testcases++;
     if ($test_status =~ /PASS/) {
       $total_pass++;
     }elsif ($test_status =~ /FAIL/) {
       $total_fail++;
     }else {
       $total_unk++;
     }
     $display_stat = 1;
     if ($parse_options) {
       $display_stat = 0 if (($parse_options =~ /pass/) && ($test_status !~ /PASS/));
       $display_stat = 0 if (($parse_options =~ /fail/) && ($test_status !~ /FAIL/));
       $display_stat = 0 if (($parse_options =~ /unk/) && ($test_status =~ /PASS|FAIL/));
     }
     $~ = 'STATUS_BODY';
     write() if ($display_stat == 1);

   }
  }
  close($TESTS_H);

  $~ = 'STATUS_FOOTER';
  write();

format STATUS_HEADER =
   -------------------------------------------------------------------------------------------------------------------------
      Domain                           |   Testcase                         |    Status  |   SimTime   | Warns | Config |
   -------------------------------------------------------------------------------------------------------------------------
.
format STATUS_BODY =
   @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<  |@<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<  | @||||||||| | @|||||||||| | @#### | @*
   $test_domain,$test_name,$test_status,$sim_time,$n_warns,$test_config
.
format STATUS_FOOTER =
   --------------------------------------------------------------------
             total testcases : @####
   $total_testcases
             total pass      : @#### (@##.##%)
   $total_pass,($total_pass*100/$total_testcases)
             total fail      : @#### (@##.##%)
   $total_fail,($total_fail*100/$total_testcases)
             total unk       : @#### (@##.##%)
   $total_unk,($total_unk*100/$total_testcases)
             run directory   : @|||||||||||||||||||||||||||
   $run_dir
   --------------------------------------------------------------------
 
.
}
#------------------------------------------------------------------------------
# SUBROUTINE: check_run_dir
#------------------------------------------------------------------------------
sub check_run_dir{
  if (($run_dir eq "") || (!(-e "$run_dir"))) {
    print "run_dir not specified";
    &die_usage;
  }
}
#------------------------------------------------------------------------------
# SUBROUTINE: check_tests_list
#------------------------------------------------------------------------------
sub check_tests_list{
  if (($tests_list eq "") || (!(-e "$simv_dir/$tests_list"))) {
    print "tests_list: $tests_list .... provide tests_list, make sure it's in simv_dir ";
    &die_usage;
  }
}
#------------------------------------------------------------------------------
# SUBROUTINE: check_simv_dir
#------------------------------------------------------------------------------
sub check_simv_dir{
  if (!(-e "$simv_dir")) {
    print "simv directory not/wrongly supplied";
    &die_usage;
  }
}
#------------------------------------------------------------------------------
# SUBROUTINE: check_file_list
#------------------------------------------------------------------------------
sub check_file_list{
  if (($file_list eq "") || (!(-e "$simv_dir/$file_list"))) {
    print "file_list not supplied";
    &die_usage;
  }
}
#------------------------------------------------------------------------------
# SUBROUTINE: parse_testlog
#------------------------------------------------------------------------------
sub parse_testlog{
  my ($testName,$testLog,$test_status,$sim_time,$n_warns,$n_errors) = @_;
  my $TEST_H = new FileHandle;
  my $test_line = "";
  my @lines = ();
  my $line_count = 0;
  $$test_status = "unk";
  $$sim_time = "-1";
  #print $testName;
  #print "Monitor.*\Q$testName\E.*Passed";
  if (-e "$testLog") {
     open($TEST_H,"<$testLog") || die "couldn't open $testLog";
     @lines = reverse <$TEST_H>;
     #while($test_line = <$TEST_H>) {
     for($line_count = 0; ($line_count<=100) && ($line_count <= $#lines) ;$line_count++){
      $test_line = $lines[$line_count];
      if ($test_line =~ /Monitor.*\Q$testName\E.*Passed/) {
        $$test_status = "PASS";
      }elsif ($test_line =~ /Monitor.*\Q$testName\E.*Failed/) {
        $$test_status = "FAIL";
      }elsif ($test_line =~ /finish at simulation time\s+(\d+)/g) {
        $$sim_time = $1;
      }elsif ($test_line =~ /warnings:\s+(\d+),\s+errors:\s+(\d+)/g) {
        $$n_warns = $1;
        $$n_errors = $2;
      }
     }
     #}
     close($TEST_H);
  }else {
    $$test_status = "notrun";
  }
  #print "parse_testlog: $testLog,$$test_status\n";
}


#------------------------------------------------------------------------------
# SUBROUTINE: s_parse_options
#------------------------------------------------------------------------------
sub s_parse_options{

  my $OptionParse = &GetOptions(
     "help"            => \$help,
     "fl=s"            => \$file_list,
     "tl=s"            => \$tests_list,
     "rdir=s"          => \$run_dir,
     "parse"           => \$parse_testlogs,
     "log=s"          => \$testlog_name,
     "status=s"        => \$parse_options,
  );

  if (!$OptionParse) {
    print "Invalid option specified.\n";
    &die_usage;
  }

  &die_usage if ($help);

}
#------------------------------------------------------------------------------
# SUBROUTINE: die_usage
#------------------------------------------------------------------------------
sub die_usage{
 print <<EOF;

   Usage: runTest.pl <options>

   Function : compiles and runs a list of testcases.

   Options:

   -h         :prints this help menu.
   -parse     :parse the testcase(s) log file in rdir directory
   -test      testcase       :testcase to be run
   -fl        file_list      :the toplevel file list for compilation
   -tl        tests_list     :list containing all testcases, along with simv options
   -rdir      run_directory  :directory where all the testcases wuld be run
   -log       Test Run Log   : Test Run log
   -status    status_options :displays only the status_options criteria, status_options can be "pass","fail","unk"

   e.g : for parsing the log files from the list
    % runTest.pl -parse -tl test_list.f -rdir ./ -log=run.rtl.log

   e.g : display only failing testcases
    % runTest.pl -parse -tl test_list.f -rdir ./ -log=run.rtl.log -status fail

EOF
    exit(1);

}
# --------------------
# 
# --------------------
sub die_tl_usage{
 print <<EOF;

   Format of contents in "tests list" file, give with option -tl to runTest.pl
   testcase <Options>
   testcase                  :name of the testcase(this has to be at the start of the line)


EOF
    exit(1);

}


