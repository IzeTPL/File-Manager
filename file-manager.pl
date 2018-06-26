#!/usr/bin/perl
$|++;

use strict;
use warnings;
use Term::ReadKey;
use Term::ANSIColor;
use File::Copy;
use Cwd;
 
ReadMode 4;
 
my $key;
my $currentDir = cwd();
my $showHidden = 0;
my $begin = 0;
my $end = 10;
my $index = 0;
my @selected;
my %selectedPath;
my $direction = "UP";
 
(my $wchar,my $hchar,my $wpixels,my $hpixels) = GetTerminalSize();

sub clr {
	print "\r", "\n" x ($_[0]);
	
	for (my $i = 0; $i <= $_[1]; ++$i) {
		print "\r", " " x ($wchar), "\e[A\r";
	}
	print "\n";
}
 
sub keyPressed {
        undef $key;
        while (!defined($key = ReadKey(-1))) {}
}

sub list {

	my @fileList;
	opendir(DIR, $currentDir) or die $!;

	while (my $file = readdir(DIR)) {
		if($showHidden) {
			push @fileList, $file;
		} else {
			next if ($file =~ m/^\.[\n\w~]/);
			push @fileList, $file;
		}
	}
	closedir(DIR);
	return @fileList;

}

sub clearSelection {
	undef @selected;
	undef %selectedPath;
}
 
sub explore {

	my @fileList = list();
	@fileList = sort { "\L$a" cmp "\L$b" } @fileList;
	if ($index == $end && $end < $#fileList) {
		$begin += 10;
		$end += 10;
	}
	if ($index == ($begin - 1) && $begin > 0) {
		$begin -= 10;
		$end -= 10;
		$index -= 9;
	}

	for (my $i = $begin; ($i < $end && $i <= $#fileList); $i++) {
		print "$fileList[$i]\n";
	} 


	print "
-----------------------------------------------------------------
-W - w gore, S - w dol, ENTER - wejdz do katalogu               -
-C - skopiuj tutaj, M - przenies tutaj, Z - zaznacz, D - usun   -
-H - pokaz/ukryj ukryte pliki, N - skasuj zaznaczenie. Q - wyjdz-
-----------------------------------------------------------------

Zaznaczone pliki: ";
	foreach (@selected) {
  		print "$_, ";
	}
	if ($direction eq "UP") {
		if ($end <= $#fileList) {
			print "\r","\e[A" x 17;
		} else {
			print "\r","\e[A" x ($#fileList - $begin + 8);
		}
		print colored("\r$fileList[$index]", 'black on_white');
	} 

	if ($direction eq "DOWN") {
		$index += 9;
		print "\r","\e[A" x 8;
		print colored("\r$fileList[$index]", 'black on_white');
	}

	if ($direction eq "NONE") {
		if ($end <= $#fileList) {
			print "\r","\e[A" x ($index - $begin);
		} else {
			print "\r","\e[A" x ($#fileList - $begin + 8);
		}
		print colored("\r$fileList[$index]", 'black on_white');
	}

	while() {
		keyPressed();
	
		if ($key eq "w" && $index > 0) {
			$direction = "DOWN";
			--$index;
			if ($index == $begin - 1) {
				clr(16, 16);
				last;
			}      
			print "\r$fileList[$index + 1]";
			print colored("\e[A\r$fileList[$index]", 'black on_white');              
		}
		
		if ($key eq "s" && $index < $#fileList) {
			$direction = "UP";
			++$index;
			if ($index == $end) {
				clr($end - $index + 8, $index - $begin + 7);
				last;
			}
			print "\r$fileList[$index - 1]\n";
			print colored("\r$fileList[$index]", 'black on_white');
		}
		
		if ($key eq "q") {
			print "\r","\e[A" x ($index - $begin);
			clr(17, 17);
			last;
		}

		if ($key eq "z") {
			my $exist = 0;
			my $location = 0;
			foreach (@selected) {
  				if ($_ eq $fileList[$index]) {
					splice (@selected, $location, 1);
					$exist = 1;
				} else {
					++$location;
				}
			}
			if (!$exist) {
				push @selected, $fileList[$index];
				$selectedPath{$fileList[$index]} = $currentDir;
				print $selectedPath{$fileList[$index]};				
			} else {
				delete $selectedPath{$fileList[$index]};
			}
			print "\r","\e[A" x ($index - $begin);
			$index = $begin;
			$direction = "UP";
			clr(17, 17);
			last;
		}

		if (($key eq "\n") && (-d $fileList[$index])) {
			chdir($fileList[$index]);
			$currentDir = cwd();
			print "\r","\e[A" x ($index - $begin);
			$index = 0;
			$direction = "UP";
			$begin = 0;
			$end = 10;
			clr(17, 17);
			last;
		}
		
		if ($key eq "c") {
			foreach (@selected) {
				copy("$selectedPath{$_}/$_", "$currentDir/$_");
			}
			print "\r","\e[A" x ($index - $begin);
			$index = $begin;
			$direction = "UP";
			clr(17, 17);
			last;
		}

		if ($key eq "m") {
			foreach (@selected) {
				move("$selectedPath{$_}/$_", "$currentDir/$_");
			}
			print "\r","\e[A" x ($index - $begin);
			$index = $begin;
			$direction = "UP";
			clr(17, 17);
			last;
		}
	
		if ($key eq "d") {
			foreach (@selected) {
				unlink "$selectedPath{$_}/$_";
			}
			clearSelection();
			print "\r","\e[A" x ($index - $begin);
			$index = $begin;
			$direction = "UP";
			clr(17, 17);
			last;
		}

		if ($key eq "n") {
			clearSelection();
			print "\r","\e[A" x ($index - $begin);
			$index = $begin;
			$direction = "UP";
			clr(17, 17);
			last;
		}

		if ($key eq "h") {
			if (!$showHidden) {
				$showHidden = 1;
			} else {
				$showHidden = 0;
			}
			print "\r","\e[A" x ($index - $begin);
			$index = $begin;
			$direction = "UP";
			clr(17, 17);
			last;
		}
	}
}

do {
	explore();
} while($key ne "q");

ReadMode 0;
