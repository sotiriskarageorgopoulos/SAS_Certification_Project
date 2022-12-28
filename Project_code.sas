*B. Base SAS Programming Using SAS Studio on SAS Viya;

*1. Data pre – processing;

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