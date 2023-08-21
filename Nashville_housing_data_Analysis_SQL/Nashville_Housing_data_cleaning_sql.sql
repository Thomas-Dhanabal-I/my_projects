/*

Cleaning Data in SQL Queries

*/

select * from Nashville_Hosusing_db..NashvilleHousing


--------------------------------------------------------------------------------------------------------------------------


-- Populate Property Address data

select a.ParcelID,a.PropertyAddress,b.ParcelID,b.PropertyAddress,ISNULL(a.PropertyAddress,b.PropertyAddress)
from Nashville_Hosusing_db..NashvilleHousing a
join Nashville_Hosusing_db..NashvilleHousing b 
on a.ParcelID=b.ParcelID and a.UniqueID<>b.UniqueID
where a.PropertyAddress is null

update a
set PropertyAddress=ISNULL(a.PropertyAddress,b.PropertyAddress)
from Nashville_Hosusing_db..NashvilleHousing a
join Nashville_Hosusing_db..NashvilleHousing b 
on a.ParcelID=b.ParcelID and a.UniqueID<>b.UniqueID
where a.PropertyAddress is null


--------------------------------------------------------------------------------------------------------------------------


-- Breaking out Property_Address into Individual Columns (Address, City)

select PropertyAddress,PropertysplitAddress,PropertysplitCity
from Nashville_Hosusing_db..NashvilleHousing 

                      ---showing address and city columns seperately-------
select SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1) as address,
SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1,LEN(PropertyAddress)) as address
from Nashville_Hosusing_db..NashvilleHousing 
                      ---updating address column-------                
alter table Nashville_Hosusing_db..NashvilleHousing 
add PropertysplitAddress nvarchar(255)
update Nashville_Hosusing_db..NashvilleHousing 
set PropertysplitAddress = SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1)
                      ---updating city column-------                
alter table Nashville_Hosusing_db..NashvilleHousing 
add PropertysplitCity nvarchar(255)
update Nashville_Hosusing_db..NashvilleHousing 
set PropertysplitCity = SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1,LEN(PropertyAddress))



-- Breaking out Owner_Address into Individual Columns (Address, City,State)
select OwnerAddress
from Nashville_Hosusing_db..NashvilleHousing 

                ---showing address,city,state columns seperately-------
select 
parsename(replace(OwnerAddress,',','.'),3),
parsename(replace(OwnerAddress,',','.'),2),
parsename(replace(OwnerAddress,',','.'),1)
from Nashville_Hosusing_db..NashvilleHousing 
                      ---updating address column-------                
alter table Nashville_Hosusing_db..NashvilleHousing 
add OwnerSplitAddress nvarchar(255)
update Nashville_Hosusing_db..NashvilleHousing 
set OwnerSplitAddress = parsename(replace(OwnerAddress,',','.'),3)
                      ---updating city column-------                
alter table Nashville_Hosusing_db..NashvilleHousing 
add OwnersplitCity nvarchar(255)
update Nashville_Hosusing_db..NashvilleHousing 
set OwnersplitCity = parsename(replace(OwnerAddress,',','.'),2)
                      ---updating state column-------                
alter table Nashville_Hosusing_db..NashvilleHousing 
add OwnersplitState nvarchar(255)
update Nashville_Hosusing_db..NashvilleHousing 
set OwnersplitState = parsename(replace(OwnerAddress,',','.'),1)
                      ----showing updated columns in table---
select *
from Nashville_Hosusing_db..NashvilleHousing 


--------------------------------------------------------------------------------------------------------------------------


-- Change Y and N to Yes and No in "Sold as Vacant" field


select distinct(soldasvacant),count(soldasvacant)
from Nashville_Hosusing_db..NashvilleHousing 
group by soldasvacant

alter table Nashville_Hosusing_db..NashvilleHousing 
add soldasvacant_C nvarchar(255)
update Nashville_Hosusing_db..NashvilleHousing 
set soldasvacant_C = 
	CASE 
        WHEN soldasvacant = 1 THEN 'YES'
        WHEN soldasvacant = 0 THEN 'NO'
        ELSE 'NULL' -- Optional, if you want to handle other values
    END


select distinct(soldasvacant_C),count(soldasvacant_C)
from Nashville_Hosusing_db..NashvilleHousing 
group by soldasvacant_C


-----------------------------------------------------------------------------------------------------------------------------------------------------------


-- Remove Duplicates
with row_num_CTE AS
(select * ,ROW_NUMBER() over (
				partition by
				ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 order by uniqueid) as row_num
from Nashville_Hosusing_db..NashvilleHousing )
delete  from row_num_CTE where row_num>1 


---------------------------------------------------------------------------------------------------------


-- Delete Unused Columns

select * from Nashville_Hosusing_db..NashvilleHousing

alter table Nashville_Hosusing_db..NashvilleHousing
drop column PropertyAddress,OwnerAddress,TaxDistrict,SoldAsVacant