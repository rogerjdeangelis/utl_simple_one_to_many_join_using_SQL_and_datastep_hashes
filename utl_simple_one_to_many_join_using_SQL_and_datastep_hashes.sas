Simple one to many join using SQL and datastep hash

 Same results in SAS and WPS with one minor difference/)

  1. Datastep HASH - same results in WPS and SAS
  2. SQL HASH (WPS Does not support the MAGIC option but does support
               the _method and WPS did use the HASH)

Not as obvious as you think? One to Many and Many to Many can produce unwanted results
if you are not careful.

SAS Forum
https://communities.sas.com/t5/Base-SAS-Programming/Hash-Table/m-p/452777


HAVE
====

WORK.HAV1ST total obs=6

                 KEY
          ====================
  Obs     DATE      CUSTOMERID    WEALTH    ADRESS   |  RULES
                                                     |
   1     01JAN01        1          1000     Stockhol |  * matches 1 and 2 in hav2nd
   2     01JAN01        2          2000     Paris    |  * matches 3 in hav2nd
   3     01FEB01        1          4000     Munich   |  * matches 4
   4     01MAR01        1          6000     New      |  * matches 8 in hav2nd
   5     01MAR01        2          3000     Cologne  |  * matches 9 in hav2nd
   6     01MAR01        3          3000     London   |  * NO MATCH
                                                     |
WORK.HAV2ND total obs=16

                 KEY                        |  RULES
          ====================              |
  Obs     DATE      CUSTOMERID    REVENUE   |  SELECT THESE FROM HAV2ND
                                            |
    1    01JAN01        1           10      |  *
    2    01JAN01        1           20      |  *
    3    01JAN01        2           30      |  *
    4    01FEB01        1           400     |  *
    5    01FEB01        2           50      |
    6    01FEB01        3           60      |
    7    01FEB01        4           30      |
    8    01MAR01        1           60      |  *
    9    01MAR01        2           30      |  *
   10    01APR01        1           60      |
   11    01APR01        2           60      |
   12    01MAY01        1           800     |
   13    01MAY01        2           608     |
   14    01MAY01        2           67      |
   15    01MAY01        4           65      |
   16    01MAY01        5           644     |


EXAMPLE OUTPUT


 Obs     DATE      CUSTOMERID    REVENUE    WEALTH    ADRESS

  1     01JAN01        1           10        1000     Stockhol   ** One to many
  2     01JAN01        1           20        1000     Stockhol   ** One to Many
  3     01JAN01        2           30        2000     Paris
  4     01FEB01        1           400       4000     Munich
  5     01MAR01        1           60        6000     New
  6     01MAR01        2           30        3000     Cologne


PROCESS
=======

* datastep;
* the ones table needs to be loaded into the hash - usually the smaller table;
data want_hash;
 if _n_ eq 1 then do;
  if 0 then set hav1st;
  declare hash h(dataset:'hav1st',multidata:'y');
  h.definekey('date','customerid');
  h.definedata('wealth','adress');
  h.definedone();
 end;
 set hav2nd;
 if h.find()=0 then output want_hash;
run;quit;

* SQL magic=103 forces a hash;
proc sql _method magic=103;
  create
    table
      want_sql as
    select
      l.*
     ,r.wealth
     ,r.adress
    from
      hav2nd as l, hav1st as r
    where
      l.date = r.date and
      l.customerid = r.customerid
;quit;

/* LOG
sqxcrta
    sqxjhsh
        sqxsrc( WORK.HAV1ST(alias = L) )
        sqxsrc( WORK.HAV2ND(alias = R) )
*/


OUTPUT
======

WORK.WANT_HASH total obs=6

Obs     DATE      CUSTOMERID    WEALTH    ADRESS      REVENUE

 1     01JAN01        1          1000     Stockhol      10
 2     01JAN01        1          1000     Stockhol      20
 3     01JAN01        2          2000     Paris         30
 4     01FEB01        1          4000     Munich        400
 5     01MAR01        1          6000     New           60
 6     01MAR01        2          3000     Cologne       30

*                _              _       _
 _ __ ___   __ _| | _____    __| | __ _| |_ __ _
| '_ ` _ \ / _` | |/ / _ \  / _` |/ _` | __/ _` |
| | | | | | (_| |   <  __/ | (_| | (_| | || (_| |
|_| |_| |_|\__,_|_|\_\___|  \__,_|\__,_|\__\__,_|

;


data hav2nd;
input date $ customerId $ Revenue $ ;
cards4;
01JAN01 1 10
01JAN01 1 20
01JAN01 2 30
01FEB01 1 400
01FEB01 2 50
01FEB01 3 60
01FEB01 4 30
01MAR01 1 60
01MAR01 2 30
01APR01 1 60
01APR01 2 60
01MAY01 1 800
01MAY01 2 608
01MAY01 2 67
01MAY01 4 65
01MAY01 5 644
;;;;
run;quit;

data hav1st;
input date $ customerId $ wealth $ Adress $;
cards4;
01JAN01 1 1000 Stockholm
01JAN01 2 2000 Paris
01FEB01 1 4000 Munich
01MAR01 1 6000 New York
01MAR01 2 3000 Cologne
01MAR01 3 3000 London
;;;;
run;quit;

*          _       _   _
 ___  ___ | |_   _| |_(_) ___  _ __  ___
/ __|/ _ \| | | | | __| |/ _ \| '_ \/ __|
\__ \ (_) | | |_| | |_| | (_) | | | \__ \
|___/\___/|_|\__,_|\__|_|\___/|_| |_|___/

;

SAS

see process


WPS

%utl_submit_wps64('
libname wrk sas7bdat "%sysfunc(pathname(work))";
data wrk.want_hash;
 if _n_ eq 1 then do;
  if 0 then set wrk.hav1st;
  declare hash h(dataset:"wrk.hav1st",multidata:"y");
  h.definekey("date","customerid");
  h.definedata("wealth","adress");
  h.definedone();
 end;
 set wrk.hav2nd;
 if h.find()=0 then output wrk.want_hash;
run;quit;

* SQL magic=103 forces a hash;
proc sql _method;
  create
    table
      wrk.want_sql as
    select
      l.*
     ,r.wealth
     ,r.adress
    from
      wrk.hav2nd as l, wrk.hav1st as r
    where
      l.date = r.date and
      l.customerid = r.customerid
;quit;
');

