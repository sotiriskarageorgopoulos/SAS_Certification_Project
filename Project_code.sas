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

	if last.Invoice_ID then output;

	label Invoice_Total_Items = 'Invoice total items';
	keep Invoice_ID Invoice_Total_Items;
run;

proc print data=project.invoice_items(obs=10) noobs;
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
	rename 'Product Type'n = Product_Type;
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
	if 1910 <= Year_Of_Birth <= 2001 then do;
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
	rename 'Product Line'n=Product_Line 'Product Type'n=Product_Type;
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
	  select pbp.Product_Line,
			 SUM(pbp.Sales_Value) as Sales format=dollarx13.2
	  from project.prom_basket_prod_sales_val pbp
	  group by pbp.Product_Line;
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

proc template;
	define statgraph SASStudio.Pie;
		begingraph;
		layout region;
		piechart category=Region response=Sales_Value /;
		endlayout;
		endgraph;
	end;
run;

ods graphics / reset width=6.4in height=4.8in imagemap;

proc sgrender template=SASStudio.Pie data=PROJECT.REVENUES_BY_REGION;
run;

ods graphics / reset;

/*For the top region found in the previous question show the contribution to the
company’s revenues per gender.*/

proc sql;
	create table project.revenue_per_gender_sp as
		select pbp.Gender, SUM(pbp.Sales_Value) AS Revenue label="Revenue" format=dollarx13.2
		from project.prom_basket_prod_inv_cus pbp
		where pbp.Region = 'SP'
		group by pbp.Gender;
quit;

proc template;
	define statgraph SASStudio.Pie;
		begingraph;
		layout region;
		piechart category=Gender response=Revenue /;
		endlayout;
		endgraph;
	end;
run;

ods graphics / reset width=6.4in height=4.8in imagemap;

proc sgrender template=SASStudio.Pie data=PROJECT.REVENUE_PER_GENDER_SP;
run;

ods graphics / reset;

*Exercise 4 - Zoom into the promotional activities by answering the following questions;

/*
Use graphs to show what is the percentage of products that are sold without
promotion and what is the percentage of products sold with promotion. Create a
format to display the 0% promotion as “No Promotion” and the 10%, 20% and 30%
as “Promotion”.
*/
proc format;
	value prom_fmt 0 = 'No Promotion'
				   0.1-0.3 = 'Promotion';
run;

data project.prom_basket_prod_inv_sales;
	merge project.prom_basket_prod_inv_id_sorted(in=pbp)
		  project.invoice_sales(in=is);
	by Invoice_ID;
	if pbp = 1 and is = 1;
	format Promotion $prom_fmt.;
run;

proc template;
	define statgraph SASStudio.Pie;
		begingraph;
		layout region;
		piechart category=Promotion / stat=pct;
		endlayout;
		endgraph;
	end;
run;

ods graphics / reset width=6.4in height=4.8in imagemap;

proc sgrender template=SASStudio.Pie data=PROJECT.PROM_BASKET_PROD_INV_SALES;
run;

ods graphics / reset;

ods graphics / reset width=6.4in height=4.8in imagemap;

proc sgplot data=PROJECT.PROM_BASKET_PROD_INV_SALES;
	vbar Promotion /;
	yaxis grid;
run;

ods graphics / reset;

/*Create pie charts to show the percentage of products that are sold on each
promotion type (use the description of the promotion and not its code). Do not
include the products sold without promotion.*/
proc format;
	value prom_type_fmt 0.1 = 'Promotion 10%'
						0.2 = 'Promotion 20%'
						0.3 = 'Promotion 30%';
run;

data project.pbpis_without_no_promotion;
	set project.prom_basket_prod_inv_sales;
	format Promotion $prom_type_fmt.;
	if Promotion = 0 then delete;
run;

proc template;
	define statgraph SASStudio.Pie;
		begingraph;
		layout region;
		piechart category=Promotion / stat=pct;
		endlayout;
		endgraph;
	end;
run;

ods graphics / reset width=6.4in height=4.8in imagemap;

proc sgrender template=SASStudio.Pie data=PROJECT.PBPIS_WITHOUT_NO_PROMOTION;
run;

ods graphics / reset;

/*
What is the distribution of sales per day of the week? Is there any difference among
the various days with respect to the number of distinct SKU’s per invoice. In order to
find the day of the week when the sale takes place use the weekday function.
*/
proc format;
	value day_name_fmt 1 = 'SUNDAY'
					   2 = 'MONDAY'
					   3 = 'TUESDAY'
					   4 = 'WEDNESDAY'
					   5 = 'THURSDAY'
					   6 = 'FRIDAY'
					   7 = 'SATURDAY';
run;

data project.invoice_sales_per_day;
	merge project.invoice_sales(in=is)
		  project.invoices_total_values(in=itv);
	by Invoice_ID;
	if itv = 1 and is = 1;
	Day = weekday(InvoiceDate);
	format Day $day_name_fmt.;
run;

ods graphics / reset width=6.4in height=4.8in imagemap;

proc sgplot data=PROJECT.INVOICE_SALES_PER_DAY;
	vbar Day / response=Invoice_Total_Values;
	yaxis grid;
run;

ods graphics / reset;

proc sort data=project.products_basket out=project.products_basket_invid_sorted;
	by Invoice_ID;
run;

data project.ispd_basket_products;
	merge project.products_basket_invid_sorted(in=pbi)
		  project.invoice_sales_per_day(in=isd);
	by Invoice_ID;
	if pbi = 1 and isd = 1;
run;

proc sql;
  create table project.distinct_sku_per_day as
	 select ibp.Day, COUNT(DISTINCT(ibp.SKU)) AS SKU_Number label="Number of distinct SKU's"
	 from project.ispd_basket_products ibp
	 group by ibp.Day;
quit;

ods graphics / reset width=6.4in height=4.8in imagemap;

proc sgplot data=PROJECT.DISTINCT_SKU_PER_DAY;
	vbar Day / response=SKU_Number;
	yaxis grid;
run;

ods graphics / reset;

/* Exercise 5
It should be also mentioned that the SKU of each product contains “hidden”
information. The ninth (9
th) digit indicates the company that supplied the product
(supplier). In order to unhide this piece of information use relevant functions and then
store it to a new column. If we assume that an SKU is 58720443450301, then the
supplier code is 4.
*/

data project.products_sup_code;
	set project.products;
	SKU_string = put(SKU, 19.);
	Supplier_Code = input(substr(strip(SKU_string),9,1), 1.);
	keep Product_ID Supplier_Code;
run;

/*
Create a frequency report and a relevant chart to show the percentage of products
sold by each supplier (use the name of the supplier and not its code). Weight the
frequency of the SKU by the quantity sold. This will show the supplier with the
highest demand.
*/
proc sort data=project.prom_basket_prod_sales_val out=project.prom_bask_prod_sv_sorted;
	by Product_ID;
run;

data project.is_prod_bask_sup_code;
	merge project.prom_bask_prod_sv_sorted(in=ibp)
		  project.products_sup_code(in=psc); 
	by Product_ID;
	if ibp = 1 and psc = 1;
run;

proc sort data=project.is_prod_bask_sup_code out=project.is_prod_bask_sc_sorted;
   by Supplier_Code;
run;

data project.is_prod_bask_sup;
	merge project.is_prod_bask_sc_sorted(in=ipb rename=(Supplier_Code=Supplier_ID))
		  project.suppliers(in=sup);
	by Supplier_ID;
	if sup = 1 and ipb = 1;
	format Sales_Value dollar15.2;
	label Sales_Value='Sales Value';
run;

proc freq data=project.is_prod_bask_sup;
	tables Supplier_Name;
run;

ods graphics / reset width=6.4in height=4.8in imagemap;

proc sgplot data=PROJECT.IS_PROD_BASK_SUP;
	vbar Supplier_Name / response=Quantity;
	yaxis grid;
run;

ods graphics / reset;

/*
Create graphs to show the percentage and actual revenues of products sold by each
supplier (use the name of the supplier and not its code).
*/

ods graphics / reset width=6.4in height=4.8in imagemap;

proc sgplot data=PROJECT.IS_PROD_BASK_SUP;
	hbar Supplier_Name / response=Sales_Value stat=percent;
	xaxis grid;
run;

ods graphics / reset;

proc template;
	define statgraph SASStudio.Pie;
		begingraph;
		layout region;
		piechart category=Supplier_Name response=Sales_Value /;
		endlayout;
		endgraph;
	end;
run;

ods graphics / reset width=6.4in height=6.4in imagemap;

proc sgrender template=SASStudio.Pie data=PROJECT.IS_PROD_BASK_SUP;
run;

ods graphics / reset;

/*
Create a cross tabulation table to show the total revenue of the company with
respect to the origins of the products sold by each supplier (Use the names of the
suppliers and the names of the countries of origins and not their codes. Put the total
revenue in the middle of the cross tabulation, the origin in the rows and the
suppliers in the columns). For this task you have to use proc tabulate (find relevant
instructions in the web or in sas help).
*/
proc sort data=project.is_prod_bask_sup out=project.is_prod_bask_sup_sorted;
	by Product_Origin;
run;

data project.is_prod_bask_sup_po;
	merge project.is_prod_bask_sup_sorted(in=ipb)
		  project.product_origin(in=po rename=(Code=Product_Origin));
	by Product_Origin;
	if ipb = 1 and po = 1;
run;

proc tabulate data=project.is_prod_bask_sup_po format=dollar14.2;
	class Country Supplier_Name;
	var Sales_Value;
	table Country, Sales_Value *(Supplier_Name) *(SUM);
run;

/*
Exercise 6
The company wants to profile its customers based on their importance so as to offer
them personalized services and products. The customer segmentation is asked to be
done based on the three parameters of the RFM model. Before the application of
the RFM model the RFM data set should be created. It is reminded that the RFM
model is based on the following three parameters:
	Recency - How recently did the customer purchase?
	Frequency - How often do they purchase?
	MonetaryValue - How much do they spend?
For this task proc sql can be used. For the calculation of R, F, M the following
functions will be useful: max, sum, count and intck (For the intck use the argument
week and the argument 16/12/2011 for today’s date).
For the creation of the variable Monetary, the price, quantity and promotion
variables should be used.
*/

proc sql;
	create table project.rfm_dataset as
		select pbp.Customer_ID label="Customer ID",
			   intck('month',max(pbp.InvoiceDate),'16dec2011'd) as Recency label="Recency",
			   count(pbp.Customer_ID) as Frequency label="Frequency",
			   sum(pbp.Sales_Value) as MonetaryValue label="Monetary Value" format=dollar15.2
		from project.PROM_BASKET_PROD_INV_CUS pbp
		group by pbp.Customer_ID;
quit;

/*
Exercise 7
Create customer segments by analyzing the RFM data set from the previous
question using SAS Visual Data Mining and Machine Learning and the three
parameters of the RFM model. It should be underlined that in order for the cluster
analysis to produce logical results the customers with extreme values of the
variables R, F, M should be excluded from the analysis. Also, if needed, the R, F, M
variables might be needed to be transformed. After the clusters are created in SAS
VDMML they should be profiled as shown in class by using SAS Visual Analytics.
Finally, the two most important clusters (justify why the selected ones are the most
important) should be further profiled by using the customer’s demographic data
(age, gender and country). 
*/

data project.rfm_demographic;
	merge project.rfm_dataset(in=rfm)
		  project.customers(in=cus);
	by Customer_ID;
	if rfm = 1 and cus = 1;
	Target = 0;
	drop First_Name Last_Name 
		  Address Postal_Code Day_Of_Birth
		  Month_Of_Birth Year_Of_Birth;
run;

/*
Exercise 8
The company is interested to change internally the store based on the products that
tend to be bought together. In order to apply this initiative the company must be
sure about the associations among the product names. You are asked to find which
products are bought together (associations of product names) in the whole data set.
Then find the associations among products in the two most important clusters
(according to your business thinking) previously identified so if a customer is found
to belong in one of them to receive the most suitable/ best proposals/ offers. For
this task Base SAS should be used to filter the customers that belong to the two
most important clusters, create the two relevant data sets and then these data sets
to be analyzed using association rules through SAS Studio. 
*/

cas; 
caslib _all_ assign;

proc format;
	value profile 1 = 'Churner'
				  2 = 'Worst'
				  3 = 'Best';
run;

*You must load file casuser.customer_profiling_project;
data project.customers_profiling;
	set casuser.customer_profiling_project(rename=(_Cluster_ID_= Customer_Profile));
	keep Customer_ID Customer_Profile Frequency 
		 Monetary Recency Age Gender Region;
	format Customer_Profile $profile.;
run;

data project.cus_prof_inv;
	merge project.customers_profiling(in=cup)
		  project.invoice(in=inv);
	if cup=1 and inv=1;
run;

data project.basket_MBA;
	set project.basket;
	where Invoice_ID is not missing and Product_ID is not missing;
	keep Invoice_ID Product_ID;
run;

*The duplicate observation removed because it is required for MBA;
proc sort data=project.basket_MBA noduprecs;
	by Product_ID;
run;

data project.cus_prof_inv_bask;
	merge project.cus_prof_inv(in=cpi)
		  project.basket_MBA(in=bas);
	if cpi=1 and bas=1;
run;

data project.cus_prof_inv_bask_prod;
	merge project.cus_prof_inv_bask(in=cpi)
		  project.products(in=pro);
	if cpi=1 and pro=1;
run;

data casuser.cus_prof_inv_bask_prod;
	set project.cus_prof_inv_bask_prod;
run;

data project.customers_churners;
	set project.cus_prof_inv_bask_prod;
	if Customer_Profile = 1;
	drop Customer_Profile;
run;

data project.customers_worst;
	set project.cus_prof_inv_bask_prod;
	if Customer_Profile = 2;
	drop Customer_Profile;
run;

data casuser.customers_churners;
	set project.customers_churners;
run;

data casuser.customers_worst;
	set project.customers_worst;
run;

ods noproctitle;

data project.PRODUCTS_BASKET_MBA;
	merge project.basket_mba(in=bas)
		  project.products(in=prod);
	by Product_ID;
	if prod = 1 and bas = 1;
run;

data casuser.PRODUCTS_BASKET_MBA;
	set project.PRODUCTS_BASKET_MBA;
run;

proc mbanalysis data=casuser.PRODUCTS_BASKET_MBA conf=0.1 items=4 
		pctsupport=0.05;
	target Product;
	customer Invoice_ID;
	output outrule=CASUSER.ALL_CUSTOMERS_MBA;
run;

ods noproctitle;

proc mbanalysis data=CASUSER.CUSTOMERS_CHURNERS conf=0.1 items=4 
		pctsupport=0.05;
	target Product;
	customer Invoice_ID;
	output outrule=CASUSER.CHURNERS_MBA;
run;

ods noproctitle;

proc mbanalysis data=CASUSER.CUSTOMERS_WORST conf=0.1 items=4 pctsupport=0.05;
	target Product;
	customer Invoice_ID;
	output outrule=CASUSER.WORST_CUSTOMERS_MBA;
run;

/*
The company wants to promote a specific product category (more specifically category
97) and want to send discount coupons for this category to customers. Since it cannot
send coupons to the whole customer base it decided to use predictive analytics so as to
send the coupons only to those customers that have the biggest probability to use the
coupons, i.e., to buy the specific category. So, it took a sample of customers, it sent to
them coupons and recorded which of those customers bought category 97 or not. The 
relevant data are stored in the data set customersAboutClass97.xlsx. The percentage of
customers that bought category 97 is 30% and the percentage of customers that did not
buy category 97 is 70%. The company will use this data set to build a predictive model
and then it will apply the model to new data.
*/

/*
Are there any missing values in the variables of the dataset? Provide a screenshot
form the software to prove it.
*/

proc format;
 value $miss_fmt ' '='Missing' other='Not Missing';
 value  miss_fmt  . ='Missing' other='Not Missing';
run;

proc freq data=project.CUSTOMERSABOUTCLASS97; 
format _CHAR_ $miss_fmt.; 
tables _CHAR_ / missing missprint nocum nopercent;
format _NUMERIC_ miss_fmt.;
tables _NUMERIC_ / missing missprint nocum nopercent;
run;

*The missing customer code has been removed;
data project.cusaboutclass97_without_missvals;
	set project.CUSTOMERSABOUTCLASS97;
	if not(missing(Customer_code));
run;