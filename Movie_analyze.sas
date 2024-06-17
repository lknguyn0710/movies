/*
Author: Lynn Nguyen
Objective: Create a macro that accept a genre and presents 
the relationships among the budget, revenue and size 
of the cast. Your macro should allow users to specify a list
of genres that they'd like to compare.

To run this code, the instructor should use method 1.
The instructor opens a SAS file labeled clearly as the main *.sas file.
there is just %LET statement where the instructor specifies the folder.
After changing the folder, the instructor runs the entire file so that 
it defines whatever macros are needed and sets up whatever new files or
data sets are needed. Then the instructor opens a new SAS Editor window
to type and run invocations of the user-oriented flexible macro that
accomplishes your assigned task.
*/
%let folder= M:\TermProject;
libname myfiles "&folder";
%let movies = &folder\tmdb_5000_movies.csv;

/*Import tmdb_5000_movies.csv*/
proc import 
    datafile= "&movies" 
    out=myfiles.extracted_movies 
    replace 
    dbms=csv;
    getnames=yes; /* Assumes the first row contains variable names */
	guessingrow=max;
run;

proc print data=myfiles.extracted_movies (obs=5);
run; 

/*Import tmdb_5000_credits.csv from a ZIP folder*/
FILENAME ZIPFILE ZIP "&folder\tmdb_5000_credits.csv.zip" member="tmdb_5000_credits.csv";

data myfiles.extracted_credits;
      %let _EFIERR_ = 0; /* set the ERROR detection macro variable */
      infile zipfile delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2 ;
         informat movie_id best32. ;
         informat title $43. ;
         informat cast $28776. ;
         informat crew $22344. ;
         format movie_id best12. ;
         format title $43. ;
        format cast $28776. ;
        format crew $22344. ;
      input
                  movie_id
                  title  $
                  cast  $
                  crew  $
      ;
      if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection macro variable */
      run;

proc print data=myfiles.extracted_credits (obs=5);
run; 

/* Merge datasets using PROC SQL */
proc sql;
    create table merged_data as
    select *
    from myfiles.extracted_movies as m
    inner join myfiles.extracted_credits as c
    on m.original_title = c.title
	and m.id = c.movie_id;

quit;


/* Create Genres data set*/
data genres;
    set merged_data;

    /* Extract genre names from genres column */
    do i = 1 to countw(genres, '}'); /* Loop through each set of curly braces in the genres column */
        /* Extract individual genre entry */
        genre_entry = scan(genres, i,'}'); /* Extracting each individual set of curly braces */
	do k = 1 to countw(genres, '"');
		genre = scan(genre_entry, 6, '"');
		end;

output; 
end;
	keep  title genre;
run; 

/*Sort Genre data set*/
proc sort data= genres out=genres_sorted;
	by title;
run;

ods rtf bodytitle file ="M:\TermProject\Genres_sorted.rtf";
title "Genres sorted by Movie Title";
proc print data=genres_sorted (obs=10);
run;
ods rtf close;

/*Create Cast data set*/
data cast;
    set merged_data; 
    
    /* Count the occurrences of "cast_id" in the cast column */
    cast_size = countc(cast, 'cast_id');

    /* Output the observation */
    output;
keep title cast_size
run;
/*Sort Cast data set*/
proc sort data= cast out=cast_sorted;
	by title;
run;

ods rtf bodytitle file ="M:\TermProject\Cast.rtf";
title "Cast sorted by Movie Title";
proc print data=cast_sorted (obs=10);
run;
ods rtf close;

/*Create Budget data set*/
data budget;
	set merged_data;
	output;
keep title budget;
run;

/*Sort budget data*/
proc sort data= budget out=budget_sorted;
	by title;
run;

ods rtf bodytitle file ="M:\TermProject\Budget.rtf";
title "Budget sorted by Movie Title";
proc print data=budget_sorted (obs=10);
run;
ods rtf close;

/*Create Revenue data set*/
data revenue;
	set merged_data;
	output;
keep title revenue;
run;

/*Sort Revenue data*/
proc sort data= revenue out=revenue_sorted;
	by title;
run;

ods rtf bodytitle file ="M:\TermProject\Revenue.rtf";
title "Revenue sorted by Movie Title";
proc print data=revenue_sorted (obs=10);
run;
ods rtf close;

/*Merge genres_sorted revenue_sorted cast_sorted budget_sorted*/
data combine;
	merge genres_sorted revenue_sorted cast_sorted budget_sorted;
	by title;
run;

/*Sort data combine*/
proc sort data= combine out=combine_sorted;
	by genre;
run;

/*removing any observations have missing value in Genre*/
data combine_sorted;
    set combine_sorted;
    where not missing(genre);
run;

ods rtf bodytitle file ="M:\TermProject\Combine.rtf";
title "Merge Genre Revenue Budget Cast by Title";
proc print data=combine_sorted (obs=10);
run;
ods rtf close;

/*Write a macro analyze relationship among budget, revenue, cast size
by genre*/

ods rtf file="M:\TermProject\Analyze.rtf";
title "Analyze Relationship of Revenue Budget Cast Size by Genre";
%macro analyze_genre(genre);

    /* Filter data by genre */
	 data filtered_data;
	 	set combine_sorted;
	 	where genre = "&genre"; /* Use the input parameter genre */
	 run;
 	/* Calculate statistics */
	 title "Summary Statistics for Budget, Revenue, and Cast Size";
	 proc means data=filtered_data;
	 	var budget revenue cast_size;
		output out=summary_stats mean=mean_budget mean=mean_revenue 
		mean=mean_cast_size;
	 run;
 
	/* Correlation analysis */
	 title "Correlation Matrix for Budget, Revenue, and Cast Size for Genre: &genre.";
	 proc corr data=filtered_data outp=correlation_matrix;
	 	var budget revenue cast_size;
	 run;

	 /* Create scatter plot Budget vs Revenue */
	 proc sgplot data=filtered_data;
		 title "Relationship between Budget, Revenue for Genre: &genre.";
		 scatter x=budget y=revenue / markerattrs=(symbol=circlefilled color=blue);
		reg x=budget y=revenue / nomarkers lineattrs=(color=red thickness=2);
	 	xaxis label='Budget ($)';
	 	yaxis label='Revenue ($)';
	 run;

	 /* Create scatter plot Revenue vs Cast Size*/
	 proc sgplot data=filtered_data;
		 title "Relationship between Revenue vs Cast Size for Genre: &genre.";
	 	scatter x=cast_size y=revenue / markerattrs=(symbol=circlefilled color=blue);
		reg x=cast_size y=revenue / nomarkers lineattrs=(color=red thickness=2);
	 	xaxis label='Cast Size (people)';
	 	yaxis label='Revenue ($)';
	 run;

	 /* Create scatter plot Budget vs Cast Size */
	 proc sgplot data=filtered_data;
		 title "Relationship between Budget vs Cast Size for Genre: &genre.";
	 	scatter x=budget y=cast_size / markerattrs=(symbol=circlefilled color=blue);
		reg x=budget y=cast_size / nomarkers lineattrs=(color=red thickness=2);
	 	xaxis label='Budget ($)';
		 yaxis label='Cast Size (people)';
	run;

	 /* Linear Regression Analysis */
	proc reg data=filtered_data ;
    	model revenue = budget cast_size;
    	title "Linear Regression Analysis for Revenue with Budget and Cast Size";
	run;
%mend;

%analyze_genre(Action); /* Call the macro with the desired genre */
%analyze_genre(genre)
ods rtf close;


