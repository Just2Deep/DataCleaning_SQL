/* 

Data cleaing in SQL queries

*/

select * 
from PortfolioProject..NashvilleHousing
--------------------------------------------------------------------------------------------------------------------

-- Standardised date format


select SaleDate, CONVERT(Date, SaleDate)
from PortfolioProject..NashvilleHousing
where SaleDate is not null

update NashvilleHousing
set SaleDate = CONVERT(Date, SaleDate)
where SaleDate is not null

ALTER TABLE NashvilleHousing
ADD SaleDateConverted Date

update NashvilleHousing
set SaleDateConverted = CONVERT(Date, SaleDate)


--------------------------------------------------------------------------------------------------------------------

-- Populate property address data when it is NULL from other similar rows


select *
from PortfolioProject..NashvilleHousing
--where PropertyAddress is null
order by PropertyAddress 

select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, COALESCE(a.PropertyAddress, b.PropertyAddress)
from PortfolioProject..NashvilleHousing as a
JOIN PortfolioProject..NashvilleHousing as b
ON a.ParcelID = b.ParcelID 
and a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is null


update a
set a.PropertyAddress = b.PropertyAddress
from PortfolioProject..NashvilleHousing as a
JOIN PortfolioProject..NashvilleHousing as b
ON a.ParcelID = b.ParcelID 
and a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is null






--------------------------------------------------------------------------------------------------------------------

-- Breaking out address into individual columns (Address, city, state)


select 
SUBSTRING(PropertyAddress, 1, CHARINDEX( ',' , PropertyAddress)  -1) as Address,
SUBSTRING(PropertyAddress, CHARINDEX( ',' , PropertyAddress) +1 , LEN(PropertyAddress)) as City
from PortfolioProject..NashvilleHousing

ALTER TABLE NashvilleHousing
ADD PropertySplitAddress NVARCHAR(255), PropertySplitCity NVARCHAR(255)

-- updating address in new column
update NashvilleHousing
set PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX( ',' , PropertyAddress)  -1) 


-- updating city in new column
update NashvilleHousing
set PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX( ',' , PropertyAddress) +1 , LEN(PropertyAddress))

-- Breaking the owner address column

select OwnerAddress,
SUBSTRING(OwnerAddress, 1, CHARINDEX(',' , OwnerAddress)-1) as Address,
SUBSTRING(OwnerAddress, CHARINDEX(',' , OwnerAddress, CHARINDEX(',' , OwnerAddress)+1) +1 , LEN(OwnerAddress)) as State
from PortfolioProject..NashvilleHousing

-- Breaking column using PARSENAME

select OwnerAddress,
PARSENAME(REPLACE(OwnerAddress, ',','.'), 3),
PARSENAME(REPLACE(OwnerAddress, ',','.'), 2),
PARSENAME(REPLACE(OwnerAddress, ',','.'), 1)
from PortfolioProject..NashvilleHousing

-- Creating new columns for the split data 
ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress NVARCHAR(255), OwnerSplitCity NVARCHAR(255) , OwnerSplitState NVARCHAR(255)

-- update the newly created split columns

update NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',','.'), 3)

update NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',','.'), 2)

update NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',','.'), 1)


--------------------------------------------------------------------------------------------------------------------

-- Change Y and N to Yes and No in "Sold as vacant" field


select distinct(SoldAsVacant), COUNT(soldasvacant)
from PortfolioProject..NashvilleHousing
group by SoldAsVacant
order by 2

select SoldAsVacant,
CASE when SoldAsVacant = 'Y' Then 'Yes'
	 when SoldAsVacant = 'N' Then 'No'
	 else SoldAsVacant
END
from PortfolioProject..NashvilleHousing

UPDATE NashvilleHousing
SET SoldAsVacant = CASE when SoldAsVacant = 'Y' Then 'Yes'
	 when SoldAsVacant = 'N' Then 'No'
	 else SoldAsVacant
END



--------------------------------------------------------------------------------------------------------------------

-- Remove duplicates

with RowNumCTE as (
Select * ,
ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY 
				 UniqueID 
				 ) row_num
from PortfolioProject..NashvilleHousing
)

DELETE 
From RowNumCTE
where row_num > 1
--order by PropertyAddress


--------------------------------------------------------------------------------------------------------------------

-- Delete unused columns

select *
from PortfolioProject..NashvilleHousing

ALTER TABLE NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress

ALTER TABLE NashvilleHousing
DROP COLUMN SaleDate


-- renaming the columns
EXEC sp_RENAME 'NashvilleHousing.SaleDateConverted' , 'SaleDate', 'COLUMN'

EXEC sp_RENAME 'NashvilleHousing.PropertySplitAddress' , 'PropertyAddress', 'COLUMN'

EXEC sp_RENAME 'NashvilleHousing.PropertySplitCity' , 'PropertyCity', 'COLUMN'

EXEC sp_RENAME 'NashvilleHousing.OwnerSplitAddress' , 'OwnerAddress', 'COLUMN'

EXEC sp_RENAME 'NashvilleHousing.OwnerSplitCity' , 'OwnerCity', 'COLUMN'

EXEC sp_RENAME 'NashvilleHousing.OwnerSplitState' , 'OwnerState', 'COLUMN'
--------------------------------------------------------------------------------------------------------------------