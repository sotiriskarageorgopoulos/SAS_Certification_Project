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
	if 1910 <= Year_Of_Birth <= 2019 then do;
		Birth_Date = mdy(Month_Of_Birth, Day_Of_Birth, Year_Of_Birth);
		Today = mdy(1,1,2019);
		Age = int((Today - Birth_Date)/365.25);
		drop Birth_Date Today;
	end;
	else delete;
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
	if age < 18 then Age_Range = "Under 18";
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
quit;

/*number of distinct SKU's for each age group*/
proc sql;
  create table project.age_group_sku as
	 select cibp.Age_Range label='age range',
			count(distinct(cibp.SKU)) AS SKU_Number label='number of distinct SKU'
	 from project.cus_inv_bask_prod cibp
	 group by cibp.Age_Range;
quit;

/*total cost of purchases for each age group*/
proc sql;
	create table project.age_group_cost as
	  select iic.Age_Range label='age range', 
			 SUM(iic.Invoice_Total_Values) AS Total_Cost label='Total Cost' format=dollarx13.2
	  from project.invoice_invtv_customer iic
	  group by iic.Age_Range;
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

*Exercise 3 - Exploration and understanding of sales;

/*
What was the level of Sales and Returns? Create a bar chart with the monetary
values.
*/

ods graphics / reset width=6.4in height=4.8in imagemap;

proc sgplot data=PROJECT.INVOICE_INVTV;
	vbar Operation / response=Invoice_Total_Values;
	yaxis grid;
run;

ods graphics / reset;

/*
Create graphs for the average basket size i.e. number of SKU’s, total monetary value,
etc and comment on your findings.
*/

data project.invoice_sales_basket;
	merge project.invoice_sales(in=ins) 
		  project.basket_invid_sorted(in=bis);
	by Invoice_ID;
	if ins = 1 and bis = 1;
run;

proc sql;
	create table project.avg_basket_size_by_date as
		select isb.InvoiceDate as Invoice_Date, 
			   AVG(isb.Quantity) as Average_Basket_Size label="Average Basket Size" format=4.2
		from project.invoice_sales_basket isb
		group by isb.InvoiceDate;
quit;

/*Average Basket Size for all invoices in 2010 to 2011, 
Maximum Products Sold and Minimum Products Sold.*/
proc sql;
	select AVG(isb.Quantity) label="Average Basket Size" format=4.2
	from project.invoice_sales_basket isb;

	create table project.products_sold_per_invoice as
		select isb.Invoice_ID, 
			   SUM(isb.Quantity) AS Products_Per_Invoice
		from project.invoice_sales_basket isb
		group by isb.Invoice_ID;

	select MAX(pspi.Products_Per_Invoice) label="Maximum Products Sold" format=4.,
		   MIN(pspi.Products_Per_Invoice) label="Minimum Products Sold" format=4.
	from project.products_sold_per_invoice pspi;
quit;

proc sql;
   select AVG(isb.Quantity) label="Average Basket Size" 
   from project.invoice_sales_basket isb;
quit;

/*Histogram of average basket size for invoices from 2010 to 2011*/
ods graphics / reset width=6.4in height=4.8in imagemap;

proc sgplot data=PROJECT.AVG_BASKET_SIZE_BY_DATE;
	histogram Average_Basket_Size /;
	yaxis grid;
run;
ods graphics / reset;

/*scatter plot of average basket size for invoices from 2010 to 2011*/
ods graphics / reset width=6.4in height=4.8in imagemap;

proc sgplot data=PROJECT.AVG_BASKET_SIZE_BY_DATE;
	scatter x=Average_Basket_Size y=Invoice_Date /;
	xaxis grid;
	yaxis grid;
run;

ods graphics / reset;

/*Create a report that shows the top products per product line and product type with
respect to sales value in descending order. Show also the subtotal sales of each
product type. 
*/

data project.prom_basket_prod_sales_val;
	set project.promotions_basket_products;
	Sales_Value = (1 - Promotion) * Product_Price * Quantity;
run;

proc contents data=project.prom_basket_prod_sales_val;
run;

proc sql;
  create table project.sales_value_by_product as
	select pbp.Product_Line, 
		   pbp.Product_Type, 
		   SUM(pbp.Sales_Value) as Sales_Value format=dollarx13.2
	from project.prom_basket_prod_sales_val pbp
	group by pbp.Product_Line, pbp.Product_Type;
quit;

proc sort data=project.sales_value_by_product;
	by descending Sales_Value;
run;

proc print data=project.sales_value_by_product noobs;
run;

proc sql;
	create table project.sales_by_product_type as 
	  select pbp.Product_Type,
			 SUM(pbp.Quantity) as Sales format=commax6.
	  from project.promotions_basket_products pbp
	  group by pbp.Product_Type;
run;

proc sort data=project.sales_by_product_type;
	by descending Sales;
run;

proc print data=project.sales_by_product_type noobs;
run;

/*
Use graphs to show the contribution to the company’s revenues of each region of
the country.
*/
proc sort data=project.prom_basket_prod_sales_val;
	by Invoice_ID;
run;

data project.prom_basket_prod_inv;
	merge project.prom_basket_prod_sales_val project.invoice; 
	by Invoice_ID;
run;

proc sort data=project.prom_basket_prod_inv out=project.prom_bask_prod_inv_cusid_sorted;
	by Customer_ID;
run;

data project.prom_basket_prod_inv_cus;
	merge project.prom_bask_prod_inv_cusid_sorted(in=pbp)
		  project.customers(in=cus);
	by Customer_ID;
	if pbp = 1 and cus = 1;
run;

proc sql;
	create table project.revenues_by_region as
		select pbp.Region, 
			   SUM(pbp.Sales_Value) as Sales_Value format=dollarx13.2
		from project.prom_basket_prod_inv_cus pbp
		group by pbp.Region;
run;

ods graphics / reset width=6.4in height=4.8in imagemap;

proc sgplot data=PROJECT.REVENUES_BY_REGION;
	vbar Region / response=Sales_Value;
	yaxis grid;
run;

ods graphics / reset;