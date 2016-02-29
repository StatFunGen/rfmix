#!/usr/bin/perl -w
use strict;

if (!$ARGV[0] || $ARGV[0] eq "help") {
  print STDERR <<EOF;

  Script to compare RFMIX (v2) maximum-likelihood state path subpopulation assignments 
  to known/expected correct results generated from simulation. 

  Usage: <RFMIX .msp.tsv output file>  <Expected results file>

EOF
  exit -1;
}

my ($output_fname, $correct_fname) = @ARGV;

exec($0) unless $output_fname && $correct_fname;

open F, "<$output_fname"
  or die "Can't open RFMIX MSP output file $output_fname ($!)";

open R, "<$correct_fname"
  or die "Can't open correct/expected result file $correct_fname ($!)";

$_ = <R>;

my @m;
my @diploid;
my @haploid12;
my @haploid21;
my $n = 0;
while(my $output_line = <F>) {
  chomp $output_line;
  next if $output_line =~ m/^#/;
  next if $output_line =~ m/^\s*$/;
  
  my ($chm, $spos, $epos, $sgpos, $egpos, $n_snps, @d) = split/\t/,$output_line;
  for(my $j=0; $j < @d; $j++) { $d[$j]++; }
  
  my $i = 0;
  while($i < $n_snps) {    
    my $correct_line = <R>;
    last unless $correct_line;

    chomp $correct_line;
    next if $correct_line =~ m/^#/;
    next if $correct_line =~ m/^\s*$/;
    
    my (undef, undef, @r) = split/\t/,$correct_line;
    my $s = 0;
    for(my $j=0; $j < @r; $j+=2) {

      if (($r[$j] == $d[$j] && $r[$j+1] == $d[$j+1]) ||
	  ($r[$j] == $d[$j+1] && $r[$j+1] == $d[$j])) {
	$diploid[$s]++;
	if ($r[$j] == $d[$j] && $r[$j+1] == $d[$j+1]) {
	  $haploid12[$s]++;
	} else {
	  $haploid21[$s]++;
	}	
      }

      $m[$d[$j]]->[$r[$j]]++;
      $m[$d[$j+1]]->[$r[$j+1]]++;
            
      $s++;
    }

    $i++;
    $n++;
  }
}
close F;
close R;

my ($diploid_accuracy, $haploid_accuracy) = (0, 0);
for(my $i=0; $i < @diploid; $i++) {
  $diploid[$i] = 0 unless $diploid[$i];
  $haploid12[$i] = 0 unless $haploid12[$i];
  $haploid21[$i] = 0 unless $haploid21[$i];
  
  my $d = $diploid[$i] / $n;
  my $h1 = $haploid12[$i] / $n;
  my $h2 = $haploid21[$i] / $n;

  my $h = $h1 > $h2 ? $h1 : $h2;
  printf "%s\t%1.1f%%\t%1.1f%%\n", $i, $h*100., $d*100.;

  $diploid_accuracy += $d;
  $haploid_accuracy += $h;
}

printf "Haploid accuracy = %1.2f%%\n", $haploid_accuracy / @diploid * 100.;
printf "Diploid accuracy = %1.2f%%\n", $diploid_accuracy / @diploid * 100.;

for(my $i=1; $i < @m; $i++) {
  print "\t$i";
}
print "\n";

for(my $j=1; $j < @m; $j++) {
  my $d = 0;
  for(my $i=1; $i < @m; $i++) {
    $m[$i]->[$j] = 0 unless $m[$i]->[$j];
    $d += $m[$i]->[$j];
  }
  for(my $i=1; $i < @m; $i++) {
    $m[$i]->[$j] /= $d + 0.1;
  }
}
for(my $i=1; $i < @m; $i++) {  
  printf "$i";
  for(my $j=1; $j < @m; $j++) {
    printf "\t%5.1f", $m[$i]->[$j] * 100.;
  }
  printf "\n"; 
}
