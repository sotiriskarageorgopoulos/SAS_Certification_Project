*B. Base SAS Programming Using SAS Studio on SAS Viya;

*Exercise 1 - Data pre – processing;

/*
For every invoice calculate the number of SKU’s that are related to it ‘Invoice total
items’. Save the output in a new SAS data set and print the first 10 observations of it.
Only the data step can be used for merging data sets. Proc sql can be used for the
statistics. It is suggested to use noprint option in proc sql because the new data set
will be large.
*/
proc sort data=project.basket out=project.basket_prod_id_sorted;
	by Product_ID;
run;

proc sort data=project.products out=project.products_prod_id_sorted;
	by Product_ID;
run;

data project.products_basket;
	merge project.products_prod_id_sorted(in=prod) project.basket_prod_id_sorted(in=basket);
	by Product_ID;
	if prod = 1 and basket = 1;
run;

proc sort data=project.products_basket out=project.products_basket_prod_id_sorted;
	by Invoice_ID;
run;

data project.invoice_items;
	set project.products_basket_prod_id_sorted;
	by Invoice_ID;
	retain Invoice_Total_Items;
	
	if first.Invoice_ID then Invoice_Total_Items = 1;
	else Invoice_Total_Items = Invoice_Total_Items + 1;

	if last.Invoice_Total_Items then output;

	label Invoice_Total_Items = 'Invoice total items';
	keep Invoice_ID Invoice_Total_Items;
run;

/*
For every invoice calculate the total value of the SKU’s that are related to it ‘Invoice
total value’. Beware that there exist price discounts that can be seen in the
promotions data set. Take into account all the invoices no matter if they are Sales or
Returns. Save the output in a new SAS data set. For this task use the proc means
with the output statement.
*/
proc sort data=project.products_basket out=project.products_basket_prom_id_sorted;
	by Promotion_ID;
run;

data project.promotions_basket_products;
	merge project.promotions(in=pr) project.products_basket_prom_id_sorted(in=pb);
	by Promotion_ID;
	if pb = 1 and pr = 1;
run;

proc sort data=project.promotions_basket_products out=project.prom_basket_prod_inv_id_sorted;
	by Invoice_ID;
run;

data project.invoices_total_values;
	set project.prom_basket_prod_inv_id_sorted;
	by Invoice_ID; 
	
    retain Invoice_Total_Values;
	if first.Invoice_ID then Invoice_Total_Values = 0;
	Invoice_Total_Values = Invoice_Total_Values + (1 - Promotion) * Product_Price * Quantity;
	if last.Invoice_ID then output;

	label Invoice_Total_Values = 'Invoice Total Values';
	keep Invoice_ID Invoice_Total_Values;
run;

data project.invoices_total_values;
	set project.prom_basket_prod_inv_id_sorted;
	by Invoice_ID; 
	
    retain Invoice_Total_Values;
	if first.Invoice_ID then Invoice_Total_Values = 0;
	Invoice_Total_Values = Invoice_Total_Values + (1 - Promotion) * Product_Price * Quantity;
	if last.Invoice_ID then output;

	label Invoice_Total_Values = 'Invoice Total Values';
	keep Invoice_ID Invoice_Total_Values;
run;

proc means data=project.invoices_total_values;
	var Invoice_Total_Values;
run;

/*
Divide the observations of the table 'Invoice’ into two new tables where in the one
the Sales transactions will be stored where as in the second the Returns transactions
will be stored. This division must be done using the variable ‘Operation’. This action
since it is not stated differently should be completed using the data step.
*/

data project.invoice_sales project.invoice_return;
	set project.invoice;
	if Operation = 'Sale' then output project.invoice_sales;
	else if Operation = 'Return' then output  project.invoice_return;
run;

/*
Calculate the customer’s age based on the fact that today’s date is 01/01/2019 and
store it into a new variable (check the validity of the dates e.g. birth year greater
than 1910 and less than 2001). Show integer values of the age without decimals.
*/

data project.customers;
	set project.customers;
	if 1910 < Year_Of_Birth < 2001 then do;
		Birth_Date = mdy(Month_Of_Birth, Day_Of_Birth, Year_Of_Birth);
		Today = mdy(1,1,2019);
		Age = int((Today - Birth_Date)/365.25);
		drop Birth_Date Today;
	end;
run;

*Exercise 2 - Describe and explain using graphs who is your customer. What is the profile of the
audience to which the company’s products are targeted?;

/* 
What are the demographic characteristics i.e. age, gender and region of the
company’s customers? 
*/

/*Customers gender in pie chart*/
proc template;
	define statgraph SASStudio.Pie;
		begingraph;
		layout region;
		piechart category=Gender / stat=pct;
		endlayout;
		endgraph;
	end;
run;

ods graphics / reset width=6.4in height=4.8in imagemap;

proc sgrender template=SASStudio.Pie data=PROJECT.CUSTOMERS;
run;

ods graphics / reset;

/*Customers regions in horizontal bar chart*/
ods graphics / reset width=6.4in height=4.8in imagemap;

proc sgplot data=PROJECT.CUSTOMERS;
	hbar Region /;
	xaxis grid;
run;

ods graphics / reset;

/*Adult customers age range in horizontal box plot*/
ods graphics / reset width=6.4in height=4.8in imagemap;

proc sgplot data=PROJECT.CUSTOMERS;
	hbox Age / boxwidth=0.4;
	xaxis grid;
run;

ods graphics / reset;

/*
Based on the age variable, create a new variable entitled Age_Range that takes the
following values:
<18 -- > “Under 18”
18 - 25 -- > “Very Young”
26 - 35 -- > “Young”
36 - 50 -- > “Middle Age”
51 - 65 -- > “Mature”
66 – 75 -- > “Old”
>= 76 -- > “Very Old”
*/

data project.customers;  
	set project.customers;
    length Age_Range $ 10;
	if age = . then Age_Range = "Under 18";
	else if 18 <= age <= 25 then Age_Range = "Very Young";
	else if 26 <= age <= 35 then Age_Range = "Young";
	else if 36 <= age <= 50 then Age_Range = "Middle Age";
	else if 51 <= age <= 65 then Age_Range = "Mature";
	else if 66 <= age <= 75 then Age_Range = "Old";
	else if age >= 76 then Age_Range = "Very Old";
run;

/*
What are the behavioral characteristics of each age group? (visits to the stores,
number of distinct SKU’s purchased, total cost of purchases). The merging of the
data sets must be done using exclusively the data step but the calculation of the
statistics e.g. visits, total cost of purchases etc can be done using proc sql. Create a
pie chart and a frequency table with the percentages of customers that belong to
each age group. Augment your analysis by providing pie charts for the behavioral
characteristics for each age group.
*/


proc sort data=project.customers out=project.customers_custid_sorted;
	by customer_id;
run;

proc sort data=project.invoice out=project.invoice_custid_sorted;
	by Customer_Id;
run;

proc sort data=project.basket out=project.basket_invid_sorted;
	by Invoice_ID;
run;

data project.customers_invoice;
	merge project.customers_custid_sorted(
			in=ccs
			rename=(customer_id = Customer_ID)
		  ) 
		  project.invoice_custid_sorted(in=ics);
	by Customer_ID;
	if ccs = 1 and ics = 1;
run;

proc sort data=project.customers_invoice out=project.cus_inv_invid_sorted;
	by Invoice_ID;
run;

data project.cus_inv_bask;
	merge project.basket_invid_sorted(in=bi)
		  project.cus_inv_invid_sorted(in=ci);
	by Invoice_ID;
	if bi=1 and ci=1;
run;

proc sort data=project.cus_inv_bask out=project.cus_inv_bask_invid_sorted;
	by Product_ID;
run;

data project.cus_inv_bask_prod;
	merge project.cus_inv_bask_invid_sorted(in=cib)
		  project.products_prod_id_sorted(in=ppi);	
	by Product_ID;
	if cib = 1 and ppi = 1;
run;

proc sort data=project.invoice out=project.invoice_invid_sorted;
	by Invoice_ID;
run;

data project.invoice_invtv;
	merge project.invoice_invid_sorted(in=iis)
		  project.invoices_total_values(in=itv);
	by Invoice_ID;
	if iis = 1 and itv = 1;
run;

proc sort data=project.invoice_invtv out=project.invoice_invtv_cusid_sorted;
	by Customer_ID;
run;

data project.invoice_invtv_customer;
	merge project.invoice_invtv_cusid_sorted(in=iic)
	      project.customers_custid_sorted(in=ccs);
	by Customer_ID;
	if iic = 1 and ccs = 1;
run;

/*number of visits store for each age group*/
proc sql;
  create table project.age_group_visits as
	  select ci.Age_Range label='age range',
		    count(*) AS Visits label='visits in store' format=commax5.
	  from  project.customers_invoice ci
	  group by ci.Age_Range;

  select * from project.age_group_visits;
quit;

/*number of distinct SKU's for each age group*/
proc sql;
  create table project.age_group_sku as
	 select cibp.Age_Range label='age range',
			count(distinct(cibp.SKU)) AS SKU_Number label='number of distinct SKU'
	 from project.cus_inv_bask_prod cibp
	 group by cibp.Age_Range;

  select * from project.age_group_sku;
quit;

/*total cost of purchases for each age group*/
proc sql;
	create table project.age_group_cost as
	  select iic.Age_Range label='age range', 
			 SUM(iic.Invoice_Total_Values) AS Total_Cost label='Total Cost' format=dollarx13.2
	  from project.invoice_invtv_customer iic
	  group by iic.Age_Range;
    select * from project.age_group_cost;
quit;

/*pie chart with percentages for each age group*/
proc template;
	define statgraph SASStudio.Pie;
		begingraph;
		layout region;
		piechart category=Age_Range / stat=pct;
		endlayout;
		endgraph;
	end;
run;

ods graphics / reset width=6.4in height=4.8in imagemap;

proc sgrender template=SASStudio.Pie data=PROJECT.CUSTOMERS;
run;

ods graphics / reset;

/*Frequency table for age groups*/
proc freq data=project.customers;
	table Age_Range;
run;

/*pie chart for total purchase cost of every age group*/

proc template;
	define statgraph SASStudio.Pie;
		begingraph;
		layout region;
		piechart category=Age_Range response=Total_Cost /;
		endlayout;
		endgraph;
	end;
run;

ods graphics / reset width=6.4in height=4.8in imagemap;

proc sgrender template=SASStudio.Pie data=PROJECT.AGE_GROUP_COST;
run;

ods graphics / reset;

/*pie chart for visits of every age group*/
proc template;
	define statgraph SASStudio.Pie;
		begingraph;
		layout region;
		piechart category=Age_Range response=Visits /;
		endlayout;
		endgraph;
	end;
run;

ods graphics / reset width=6.4in height=4.8in imagemap;

proc sgrender template=SASStudio.Pie data=PROJECT.AGE_GROUP_VISITS;
run;

ods graphics / reset;

/*pie chart for disinct SKU of every age group*/
proc template;
	define statgraph SASStudio.Pie;
		begingraph;
		layout region;
		piechart category=Age_Range response=SKU_Number /;
		endlayout;
		endgraph;
	end;
run;

ods graphics / reset width=6.4in height=4.8in imagemap;

proc sgrender template=SASStudio.Pie data=PROJECT.AGE_GROUP_SKU;
run;

ods graphics / reset;