#!/usr/bin/env perl -w

=head1 Documentation

This program creates an HTML Skeleton for a website

 Author: Christian Rees, 2000 <rees@genome.stanford.edu>
 Re-visited: John Matese, 2004 <jcmatese@genomics.princeton.edu>

_______________________________________________________________________
   Usage:
$0 -template <file/name> -sitename <sitename> [-rootpath <path/to/website> -font <'font_face(s)'> -accent <color> -image </path/to/image.gif> -bgcolor <page_color> -verbose]
_______________________________________________________________________


    -template = required input file containing the project name and
	        page titles

    -out      = optional destination (directory) where all the website
	        files will be created.  If no -out destination is
	        provided, it default to the working directory

    -sitename = optional text_string which will be the name of a newly
	        created directory, where all the web pages will be
	        written to.  Only necessary if a site-enclosing
	        directory is not already made; A simple one word
	        string is all that is needed.

    -font     = optional font face for the website (written to
 	        stylesheet) defaults to '$font' ; written/editable in
 	        stylesheet

    -accent   = optional color for table header cells (website accent
                color) defaults to '$thcolor' ; written/editable in
                stylesheet

    -image    = optional image which could be displayed at the top of
	        every page.  The value for the image should be a
	        filepath.  If no image is specified
	        the header defaults to the project name within the
	        template, as a text header

    -bgcolor  = optional background color for all webpages (body
                backgroud) defaults to '$bgcolor' ; written/editable
                in stylesheet

    -verbose  = show feedback messages during run

    -help     = print this message

    -getTemplate =  writes out an example template file,
                    which the user can edit

* a configuration file in the following format determines the page layout for the website:

 My Super Website
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
 authors=the people who worked on the XXX project
 links=A collection of interesting hyperlinks

=cut

use strict;

use Getopt::Long;
use File::Copy;
use Cwd;
use File::Basename;

use CGI qw/:standard :netscape/;
use CGI::Pretty;


# the following are the default options for making a website that will
# be utilized by getopts

my ($templatefile, $out, $sitename, $pagecolor, $image, $help, $getTemplate, $verbose);

# defaults for this client
my $font     = "technical, Verdana, Tahoma, Arial, sans-serif";
my $thcolor  = "#9B664E"; # "LightSlateGrey", "grey" # color for header backgrounds
my $thfont   = "copperplate";
my $bgcolor  = "#E5D8C2"; # "white", background color

my %args = (template => \$templatefile,
	    out      => \$out,
	    sitename => \$sitename,
	    font     => \$font,
	    accent   => \$thcolor,
	    image    => \$image,
	    bgcolor  => \$bgcolor,
	    verbose  => \$verbose,
	    help     => \$help,
	    getTemplate  => \$getTemplate);


unless( &GetOptions( \%args, "template=s", "out=s", "sitename=s", "font=s", "accent=s", "image=s", "bgcolor=s", "verbose", "help", "getTemplate") ){
    &Usage;
}

&WriteTemplate if ($getTemplate);
&Usage if ($help || !$templatefile);


if($verbose) {

    print <<EOF;

Automatic Website Generator
---------------------------
Author:     Christian Rees, (c) Stanford University 2000
Re-visited: John Matese, Princeton University

EOF
}

my ($projectName, $pageNamesArrRef) = &readPageTitles();


if ($sitename) {

    &MakeDirectory($out, $sitename);

}elsif($out) {

    # if they didn't ask for a new directory to be created (handled
    # above, and we've already changed to that directory), but the
    # user did specify that they wanted files created somewhere else
    # but the current working directory, go to that 'out' directory
    # now

    $out =~ s|/*$|/|; # ensure trailing slash

    unless(-d $out) {die "The specifed destination directory ($out) does not exist, or is not a directory."}
    unless(-w $out) {die "The specifed destination ($out) is not writeable."};

    $verbose && print "Changing directory to $out\n";

    chdir($out) || die "Cannot chdir to $out ($!)";
}


if ($image) {

    unless(-f $image && -r $image) {
	print "WARNING: $image is not a file or is not readable.  Will not copy it to the site.\n";;
	undef($image);
    }else{
	
	my $cwd = getcwd();
	$verbose && print "Copying $image to $cwd\n";
	copy($image, $cwd) || die "Could not copy header image ($image) to the website ($cwd): $!\n";
    }
}


my %pageIndex;

my $stylesheet = lc($projectName);
$stylesheet =~ s/ /_/ig;
$stylesheet .= ".css";

# ------------------------------------------
# create skeleton & content pages for each section 
# including SSI statements for the content


for (my $i=0; $i<@{$pageNamesArrRef}; $i++) {


    $verbose && print "Writing $$pageNamesArrRef[$i].shtml and $$pageNamesArrRef[$i].html\n";

    open (OUT, ">$$pageNamesArrRef[$i].shtml") || die "cannot open file, $$pageNamesArrRef[$i]: $!\n";
    select (OUT);
    create_skeleton($$pageNamesArrRef[$i]);
    select(STDOUT); 
    close (OUT);

    if ($i==0){
	$verbose && print "\tMaking a link to $$pageNamesArrRef[$i].shtml from index.shtml\n";
	symlink("$$pageNamesArrRef[$i].shtml", "index.shtml") || warn "\tWARNING: Cannot symlink file.txt: $!.  Continuing on, as this link is only a convenience.\n";
    }

    open (OUT, ">$$pageNamesArrRef[$i].html") || die "cannot open file, $$pageNamesArrRef[$i]: $!\n";
    select (OUT);
    create_content($$pageNamesArrRef[$i]);
    select(STDOUT); 
    close (OUT);

}


# ------------------------------------------
# create the left menu file & footer file

$verbose && print "Writing leftmenu.html\n";
open (OUT, ">leftmenu.html") || die "cannot open file: $!\n";
select (OUT);
create_left_menu($pageNamesArrRef);
select(STDOUT);
close (OUT);

$verbose && print "Writing header.html\n";
open (OUT, ">header.html") || die "cannot open file: $!\n";
select (OUT);
create_header();
select(STDOUT);
close (OUT);

$verbose && print "Writing footer.html\n";
open (OUT, ">footer.html") || die "cannot open file: $!\n";
select (OUT);
create_footer($pageNamesArrRef);
select(STDOUT);
close (OUT);

$verbose && print "Writing $stylesheet\n";
open (OUT, ">$stylesheet") || die "cannot open file: $!\n";
select (OUT);
create_stylesheet();
select(STDOUT);
close (OUT);



# ------------------------------------------
# end of main program
exit;


# ---------------------------------------------------------------------
sub MakeDirectory {
# ---------------------------------------------------------------------
#  this subroutine makes directories into which the html skeleton
#  files are created

    my ($out, $sitename) = @_;

    # if they didn't specify an out directory, find where we are
    if (!$out) {
	$out = getcwd();
    }

    $out =~ s|/*$|/|; # ensure trailing slash

    unless(-d $out) {die "The specifed destination directory ($out) does not exist, or is not a directory."}
    unless(-w $out) {die "The specifed destination ($out) is not writeable."};


    $sitename =~ tr/ /_/; # transform spaces to underscores

    my $sitepath = $out.$sitename;
    $verbose && print "Creating website directory: $sitepath\n";
    mkdir($sitepath) || die "Could not make directory ($sitepath) : $!\n";

    $verbose && print "Changing directory to $sitepath\n";
    chdir($sitepath) || die "Cannot chdir to $sitepath ($!)";

}



# ---------------------------------------------------------------------
sub readPageTitles {
# ---------------------------------------------------------------------
# this subrotine simply read in the template file and processes it for
# the project name and pagetitles

    $verbose && print "Reading page titles : $templatefile\n";

    open(IN, "$templatefile") || die "cannot open Page Titles: $!\n";
    my @titles = (<IN>);
    chomp(@titles);
    close(IN);

    my $project = shift @titles;
    chomp($project);

    my @names;

    foreach (@titles) {

	# substitute all instances of XXX with project name within the
	# line
	$_ =~s/XXX/$project/g;

	chomp;    # no newline
	s/#.*//;  # no comment
	s/\/\///; # no record delimiter
	s/^\s+//; # no leading white
	s/\s+$//; # no trailing white
#	s/ //g;
	next unless length; # anything left?

	$verbose && print "\t$_\n";

	my ($key, $value) = split(/\s*=\s*/, $_, 2);
	
	push (@names, $key);

	$pageIndex{$key} = $value;
    }

    return ($project, \@names);

}


# ---------------------------------------------------------------------
sub create_skeleton {
# ---------------------------------------------------------------------
# this subroutines writes out the various files used to comprise the
# website skeleton

    my $title = shift;

    my $main_table = table( # attributes
			    {-cellpadding=>'0',
			     -cellspacing=>'6',
			     -border=>'0',
			     -width=>'655'
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

			       th({-width   => '3'},
				  br()
				  ),
			       
			       "<!-- MIDDLE ROW: THIRD COLUMN -->",

			       td({-valign => 'top',
				   -halign => 'left',
				   -width  => '552'},
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
    
    print start_html(-title => $projectName.' > '.ucfirst($title),
		     -style => {-src => $stylesheet});
    
#    print center($main_table);
 
    print $main_table;
   
    print end_html();

}

sub create_stylesheet {

    print <<EOF;

a         { text-decoration: none }

a:hover   { color: red; text-decoration: underline }

body      {
            background-color: $bgcolor ;
	    font-family: $font ;
}

th        {
            background-color: $thcolor;
	    font-family: copperplate;
}

EOF

}

# ---------------------------------------------------------------------
sub create_content {
# ---------------------------------------------------------------------
# print the main content page/table intended for server-side inclusion

    my $title = shift;

    my $defaultRows = &create_default_rows(lc($title));

    print table({ -cellspacing => '0',
		  -cellpadding => '5',
		  -valign      => 'TOP',
		  -width       => '100%',
		  -border      => '0'
		  }, 
		
		Tr(
		   th(
		      ucfirst($title)."&nbsp;"
		      ),
		   ),
		
		Tr(
		   td(
		      ul(
			 br,
			 li($pageIndex{$title}."&nbsp;")
			 )
		      )
		   ),
		$defaultRows
		);

}


# ---------------------------------------------------------------------
sub create_default_rows {
# ---------------------------------------------------------------------
# for some page titles(links, software), we're going to assume that a
# little default content is not a bad thing (they can always delete
# it)

    my $title = shift;

    my $defaultRows = undef;

    if ($title eq 'links') {

	$defaultRows = Tr(
			  td(
			     a({-href=>'http://puma.princeton.edu/'},
			       img({-src=>"http://genomics-pubs.princeton.edu/images/pumadb_minibanner.gif"}),
			       "Princeton University MicroArray database")
			     )
			  ).
			Tr(
			   td(
			      a({-href=>"http://www.yeastgenome.org/"},
				img({-src=>"http://genomics-pubs.princeton.edu/images/sgd_thumbnail.gif"}),
				"Saccharomyces Genome Database")
			      )
			   ).
			   "\n<!--IF YOU HAVE A PUBLICATION IN PUMAdb, REPLACE THE ### IN THE URL BELOW-->\n".
			   "<!--WITH THE PUBLICATION_NO ASSIGNED BY THE DATABASE-->\n\n".
			   "<!--\n".
			 Tr(
			    td(
			       a({-href=>"http://puma.princeton.edu/cgi-bin/publication/viewPublication.pl?pub_no=###"},
				 img({-src=>"http://genomics-pubs.princeton.edu/images/pumadb_minibanner.gif"}),
				 "Published data in the Princeton University MicroArray database")
			       ).
			    "\n-->\n\n"
			    );


    }elsif($title eq 'software') {

	$defaultRows = Tr(
			  td(
			     a({-href=>"http://jtreeview.sourceforge.net/"},
			       img({-src=>"http://genomics-pubs.princeton.edu/images/treeView.gif"}),
			       "Java TreeView")
			     )
			  );


    }elsif($title eq 'data') {

	$defaultRows = Tr(
			  td("\n<!--IF YOU HAVE A PUBLICATION IN PUMAdb, REPLACE THE ### IN THE URL BELOW-->\n".
			     "<!--WITH THE PUBLICATION_NO ASSIGNED BY THE DATABASE-->\n\n".
			     a({-href=>"http://puma.princeton.edu/cgi-bin/publication/viewPublication.pl?pub_no=###"},
			       img({-src=>"http://genomics-pubs.princeton.edu/images/pumadb_minibanner.gif"}),
			       "Published data in the Princeton University MicroArray database")
			     )
			  );
    }

    return($defaultRows);

}

# ---------------------------------------------------------------------
sub create_left_menu {
# ---------------------------------------------------------------------
# creates the left navigation menu

    my $namesArrRef = shift;

    my @table;

    foreach my $name (@{$namesArrRef}) {

	my $tRow = th(
		   a({-href => "$name.shtml"},
		     ucfirst($name)."&nbsp;"
		     )
		   );
	
	push @table, $tRow;
	
	$tRow = td({-height =>'60',
		    -valign =>'top'},
		   font({-size=>'2'},
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
		 -align       => 'left'
		 }, 
		
		Tr(\@table)
		
		);
    
}


# ---------------------------------------------------------------------
sub create_header {
# ---------------------------------------------------------------------
# just prints the html for the header (either image or text)


    # empty string to hold for html src
    my $img = center( img({-src=>'your_image.png'}) );
    my $text = center( h1($projectName) );

    if ($image) {

	my ($base,$path,$type) = fileparse($image);
	$img  = center( img({-src=>"$base"}) );

	print <<EOF;

$img

<!-- The header can be either image or text.  Comment-out the -->
<!-- appropriate section (above|below).                       -->

<!--
$text-->

EOF

    }else{

	print <<EOF;

<!--
$img-->

<!-- The header can be either image or text.  Comment-out the      -->
<!-- appropriate section (above|below, and specify the image src). -->

$text

EOF

    }

}

# ---------------------------------------------------------------------
sub create_footer {
# ---------------------------------------------------------------------
# subroutine writes the navigation footer at the bottom of each page

    my $namesArrRef = shift;

    my @footer;

    foreach my $name (@{$namesArrRef}) {

	push @footer, a({-href=>"$name.shtml"}, ucfirst($name));
	
    }

    my $all_footer = "<!-- Begin footer -->";
    
    $all_footer .= "[ ";

    $all_footer .= join(" | ", @footer);

    $all_footer .= " ]";
    
    $all_footer .= "<!-- End footer -->";

    my $footer = p(
		   center(
			  font({-face =>$font,
				-size =>'2'},
			       $all_footer
			       )
			  )
		   );

    print $footer;
}


# ---------------------------------------------------------------------
sub Usage {
# ---------------------------------------------------------------------
# this subroutine simply prints out a usage message if the minimal
# arguments are not passed


    print STDOUT <<EOF;

   $0 is a simple script to create a skeleton website, based on the
   user-defined template
_______________________________________________________________________
   Usage:
$0 -template <file/name> [-sitename <sitename> -out <destination/dir/> -font <'font_face(s)'> -accent <color> -image </path/to/image.gif> -bgcolor <page_color> -verbose]
_______________________________________________________________________


    -template = required input file containing the project name and
	        page titles For more information on the template
	        format, try 'pod2text $0'

    -out      = optional destination (directory) where all the website
	        files will be created.  If no -out destination is
	        provided, it defaults to the current working directory

    -sitename = optional text_string which will be the name of a newly
	        created directory, where all the web pages will be
	        written to.  Only necessary if a site-enclosing
	        directory is not already made; A simple one word
	        string is all that is needed.

    -font     = optional font face for the website
 	        defaults to '$font' ;
 	        written/editable in stylesheet

    -accent   = optional color for table header cells (website accent
                color) defaults to '$thcolor' ;
                written/editable in stylesheet

    -image    = optional image which could be displayed at the top of
	        every page.  The value for the image should be a
	        filepath.  If no image is specified
	        the header defaults to the project name within the
	        template, as a text header

    -bgcolor  = optional background color for all webpages (body
                backgroud) defaults to '$bgcolor' ;
                written/editable in stylesheet

    -verbose  = show feedback messages during run

    -help     = print this message

    -getTemplate =  writes out an example template file,
                    which the user can edit, and exits


Many of the optional arguments can be configured afterwards, in the
resulting stylesheet.

EOF

(!$templatefile && !$help) && print "ERROR : You did not provide a template file to work on.  \n\n";

    exit;


}


# ---------------------------------------------------------------------
sub WriteTemplate {
# ---------------------------------------------------------------------
# this subroutine simply opens a file titled page_titles.txt and
# writes out an editable template, and exits


    my $temp = "site_template.txt";

    $verbose && print STDOUT "Writing an example template file : $temp \n";

    open (CONF, ">$temp") || die "Couldn't open example template file, $temp\n";

    print CONF <<EOF;
My Super Website
# Above is the project title. It has to be in the first line.

# configuration for the makeWebsite.pl script
# -------------------------------------------
# author: Christian Rees, (c) 2000, <rees\@genome.stanford.edu>
 
# This file defines the website skeletons layout
# Change the values below for your own purposes.

# The following lines define the sections of your website.
# Each section will have it's own page.
# If you put XXX into a section description, it will
# be replaced with the project title.
 
home=XXX Homepage
projects=Some stuff I did
software=Programs you might like
authors=the people who worked on the XXX project
links=A collection of interesting hyperlinks
EOF

    close(CONF);

    $verbose && print STDOUT "\nYou can now edit $temp \n",
    "and then re-run $0 \n",
    "using the option \'-template $temp)\' .\n\n";

    $verbose && print STDOUT "Finished.  Exiting... \n";

    exit(0);

}
