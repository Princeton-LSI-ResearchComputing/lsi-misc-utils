#!/usr/local bin/perl

=head1 Documentation

This program creates an HTML Skeleton for a website

Author: Christian Rees, 2000 <rees@genome.stanford.edu>
Re-visited: John Matese, 2004 <jcmatese@genomics.princeton.edu>


* a configuration file in the following format determines the page layout for the website:

Mikes Stuff
# Above is the project title. It has to be in the first line.

# configuration for the makeWebsite.pl script
# -------------------------------------------
# author: Christian Rees, (c) 2000, <rees@genome.stanford.edu>

# This file defines the website skeletons layout
# Change the values below for your own purposes.

# The following lines define the sections of your website.
# Each section will have it's own page.
# If you put XXX into a section description, it will
# be replaced with the project title.

home=XXX Homepage
projects=Some stuff I did
software=Programs you might like
authors=the people who did this
links=A collection of interesting hyperlinks

=cut

use strict;

use Getopt::Long;

use CGI qw/:standard :netscape/;
use CGI::Pretty;

my $projectName;
my @pageNames;

my $templatefile = shift(@ARGV);

&readPageTitles(); 

my %pageIndex; 

my $font_face = "Verdana, Tahoma, Arial, sans-serif";
my $hdrbgcolor= "#18067D"; # grey = #EEEEEE # color for header backgrounds
my $color     = "white"; # font color
my $name;

my $stylesheet;

print "Automatic Website Generator\n";
print "----------------------------\n";
print "Author: Christian Rees, (c) Stanford University 2000;\nRe-factored, John Matese, Princeton University\n";
print "Press <Control-D> to continue\n";

# ------------------------------------------
# create skeleton & content pages for each section 
# including SSI statements for the content

foreach $name ( @pageNames ) {

    open (OUT, ">$name.shtml") || die "cannot open file: $!\n";
    select (OUT);
    create_skeleton($name);
    select(STDOUT); 
    close (OUT);
    
    open (OUT, ">$name.html") || die "cannot open file: $!\n";
    select (OUT);
    create_content($name);
    select(STDOUT); 
    close (OUT);
    
}

# ------------------------------------------
# create the left menu file & footer file

open (OUT, ">leftmenu.html") || die "cannot open file: $!\n";
select (OUT);
create_left_menu();
select(STDOUT); 
close (OUT);

open (OUT, ">header.html") || die "cannot open file: $!\n";
select (OUT);
create_header();
select(STDOUT); 
close (OUT);

open (OUT, ">footer.html") || die "cannot open file: $!\n";
select (OUT);
create_footer();
select(STDOUT); 
close (OUT);

open (OUT, ">$stylesheet") || die "cannot open file: $!\n";
select (OUT);
create_stylesheet();
select(STDOUT); 
close (OUT);



# ------------------------------------------

exit;

# ---------------------------------------------------------------------
sub readPageTitles {
# ---------------------------------------------------------------------

    my ($key, $value);

    open(IN, "$templatefile") || die "cannot open Page Titles: $!\n";
    my @titles = (<IN>);
    chomp(@titles);
    close(IN);

    $projectName = shift @titles;

    foreach (@titles) {

	chomp;    # no newline
	s/#.*//;  # no comment
	s/\/\///; # no record delimiter
	s/^\s+//; # no leading white
	s/\s+$//; # no trailing white
#	s/ //g;
	next unless length; # anything left?
#       print "$_\n";
	($key, $value) = split(/\s*=\s*/, $_, 2);
#	$tmphash{$var} = $value; 
	
#	($key, $value) = split(/=/, $_);
	push @pageNames, $key;

	$value =~ s/XXX/$projectName/;
	$pageIndex{$key} = $value;
    }


}

# ---------------------------------------------------------------------
sub create_skeleton {
# ---------------------------------------------------------------------

    my $title = shift;

    my $main_table = table( # attributes
			    {-cellpadding=>'0',
			     -cellspacing=>'6',
			     -border=>'0',
			     -width=>'620'
			     },
			    
			    "<!-- TABLE TOP ROW -->",
			    
			    Tr(
			       td({-colspan=>3},
				  '<!--#include file="header.html" -->'
				  )
			       ),
			    
			    "<!-- TABLE MIDDLE ROW -->",

			    Tr(
			       
			       "<!-- MIDDLE ROW: FIRST COLUMN -->",

			       td({
				   -width       => '120',
				   -cellpadding => '0',
				   -valign      => 'top'
				   },
				  
				  '<!--#include file="leftmenu.html" -->'
				  ),
			       
			       "<!-- MIDDLE ROW: SECOND COLUMN -->",

			       td({-bgcolor => $color,
				   -width   => '2'},
				  br()
				  ),
			       
			       "<!-- MIDDLE ROW: THIRD COLUMN -->",

			       td({-valign => 'top',
				   -halign => 'left',
				   -width  => '498'},
				  '<!--#include file="'.$title.'.html" -->'
				  )			  
			       ),
			    
			    "<!-- TABLE SECOND TO LAST ROW -->",

			    Tr(
			       td({-colspan=>3},
				  br()
				  )
			       ),

			    "<!-- TABLE BOTTOM ROW -->",

			    Tr(
			       td({-colspan=>3},
				  '<!--#include file="footer.html" -->'
				  )
			       ),
			    
			    
			    );
    
    # generate link to a cascading stylesheet file by the same name as the project,
    # lowercased and spaces exchanged against underscores '_'

    $stylesheet = lc($projectName);
    $stylesheet =~ s/ /_/ig;
    $stylesheet .= ".css";
    
    print start_html(-title   => $projectName.' > '.ucfirst($title),
		     -bgcolor => '#FFFFFF',
#		     -link    => '#770000',
		     -link    => $color,
		     -vlink   => '#0000AA',
		     -style   => {-src => $stylesheet});
    
#    print center($main_table);
 
    print $main_table;
   
    print end_html();

}

sub create_stylesheet {

    my $fstylesheet = "a {  text-decoration: none}\n";
    $fstylesheet   .= "a:hover   {  color: red; text-decoration: underline}\n";
    $fstylesheet   .= "a:visited {  color: $color }\n";
    $fstylesheet   .= "body { font-face: verdana, arial, sans-serif }\n";

    print $fstylesheet;

}

# ---------------------------------------------------------------------
sub create_content {
# ---------------------------------------------------------------------

    my $title = shift;
    
    print table({ # -bgcolor=>$hdrbgcolor,
	          -cellspacing => '0',
		  -cellpadding => '5',
		  -valign      => 'TOP',
		  -width       => '100%',
		  -border      => '0'
		  }, 
		
		Tr(
		   td({ -bgcolor =>$hdrbgcolor },
		      font({-face => $font_face,
			    -size => '5',
			    -width =>'100%'},
			   b(
			     ucfirst($title)."&nbsp;"
			     )
			   ),
		      )
		   ),
		
		Tr(
		   td(
		      font({-face=>$font_face},
			   ul(
			      br,
			      li($pageIndex{$title}."&nbsp;")
			      )
			   )
		      )
		   )
		);
    
#    print table({-cellspacing=>'0',
#		 -border=>'0',
#		 -width=>'100%'},
		
#		Tr(
#		   td(
#		      font({-face=>$font_face},
#			   ul(
#			      br,
#			      li($pageIndex{$title}."&nbsp;")
#			      )
#			   )
#		      )
#		   )
#		);
    
}

# ---------------------------------------------------------------------
sub create_left_menu {
# ---------------------------------------------------------------------

    my @table;
    my $tRow;

    foreach $name (@pageNames) {

	$tRow = td({-bgcolor=>$hdrbgcolor},
#		    -width=>'100%'},
		   font({-size=>'2',
			 -face=>$font_face
			 },
			b(
			  a({-href => "$name.shtml"},
			    ucfirst($name)."&nbsp;"
			    )
			  )
			)
		   );
	
	push @table, $tRow;
	
	$tRow = td({-bgcolor=>"white",
		    -height =>'60',
#		    -width  =>'100%',
		    -valign =>'top'},
		   font({-size=>'2',
			 -face=>$font_face
			 },
			$pageIndex{$name},
			"&nbsp;",
			br(),

			)
		   );
	
	push @table, $tRow;
	
    }
    
    print table({-border      => '0',
		 -cellpadding => '3',
		 -cellspacing => '1',
#		 -width       => '110',
		 -align       => 'left'
		 }, 
		
		Tr(\@table)
		
		);
    
}

# ---------------------------------------------------------------------
sub create_header {
# ---------------------------------------------------------------------

    my $header = center( img({-src=>'/mopo/images/header.gif'}) );

    print $header;

}

# ---------------------------------------------------------------------
sub create_footer {
# ---------------------------------------------------------------------

    my @footer;

    foreach $name (@pageNames) {

	push @footer, a({-href=>"$name.shtml"}, ucfirst($name));
	
    }

    my $all_footer = "<!-- Begin footer -->";
    
    $all_footer .= "[ ";

    $all_footer .= join(" | ", @footer);

    $all_footer .= " ]";
    
    $all_footer .= "<!-- End footer -->";

    my $footer = p(
		   center(
			  font({-face =>$font_face,
				-size =>'2'},
			       $all_footer
			       )
			  )
		   );

    print $footer;
}
