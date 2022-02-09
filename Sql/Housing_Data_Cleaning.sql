-- SQL data Cleaning, using MS sql

-- Check columns
SELECT * 
FROM sys.columns 
WHERE object_id = OBJECT_ID('dbo.housing')

-- check data format
SELECT *
FROM dbo.housing
ORDER BY UniqueID
    OFFSET 0 ROWS
    FETCH NEXT 10 ROWS ONLY;


-- change Date Format
SELECT SaleDate, CONVERT(Date, SaleDate)
FROM dbo.housing

ALTER TABLE dbo.housing
ADD sale_date_converted Date

UPDATE dbo.housing
SET sale_date_converted = CONVERT(Date, SaleDate)

select sale_date_converted from dbo.housing

------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Populate property address data, full NULL data
SELECT ParcelID,PropertyAddress
FROM dbo.housing
ORDER BY PropertyAddress

-- 1 ParcelID refer to 1 PropertyAddress
SELECT a.ParcelID,a.PropertyAddress,b.ParcelID,b.PropertyAddress
FROM dbo.housing a
JOIN dbo.housing b
    on a.ParcelID = b.ParcelID
    AND a.[UniqueID]<>b.[UniqueID]
where a.PropertyAddress IS NULL


-- fill Address with reference to ParcelID
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM dbo.housing a
JOIN dbo.housing b
    on a.ParcelID = b.ParcelID
    AND a.[UniqueID]<>b.[UniqueID]

------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Breaking out address into Individual Columns (address, City, State)
SELECT PropertyAddress FROM dbo.housing

SELECT 
SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1 ),
SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1 ,LEN(PropertyAddress))
FROM dbo.housing 

ALTER TABLE dbo.housing
ADD propertySplitAddress NVARCHAR(255)

UPDATE dbo.housing
SET propertySplitAddress = SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1)


ALTER TABLE dbo.housing
ADD propertySplitCity NVARCHAR(255)

UPDATE dbo.housing
SET propertySplitCity = SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1 ,LEN(PropertyAddress))


SELECT PropertyAddress, propertySplitAddress,propertySplitCity
FROM dbo.housing 
------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- handle with Owner Address
SELECT OwnerAddress
FROM dbo.housing

SELECT OwnerAddress, 
PARSENAME(REPLACE(OwnerAddress,',','.'),3),
PARSENAME(REPLACE(OwnerAddress,',','.'),2),
PARSENAME(REPLACE(OwnerAddress,',','.'),1)
FROM dbo.housing

ALTER TABLE dbo.housing
ADD OwnerSplitAddress NVARCHAR(255),
OwnerSplitCity NVARCHAR(255),
OwnerSplitState NVARCHAR(255)

UPDATE dbo.housing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',','.'),3),
OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',','.'),2),
OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',','.'),1)

SELECT OwnerAddress, OwnerSplitAddress, OwnerSplitCity, OwnerSplitState
FROM dbo.housing

------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Change Y and N to Yes and No in "Sold as Vacant"

SELECT DISTINCT SoldAsVacant, COUNT(SoldAsVacant)
FROM dbo.housing
Group BY SoldAsVacant


SELECT SoldAsVacant
, Case
    when SoldAsVacant = 'Y' Then 'Yes'
    when SoldAsVacant = 'N' Then 'No'
    ELSE SoldAsVacant
    END
FROM dbo.housing

Update dbo.housing
SET SoldAsVacant = Case 
    when SoldAsVacant = 'Y' Then 'Yes'
    when SoldAsVacant = 'N' Then 'No'
    ELSE SoldAsVacant
    END

SELECT DISTINCT SoldAsVacant, COUNT(SoldAsVacant)
FROM dbo.housing
Group BY SoldAsVacant


------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Remove Duplicates

-- find duplicates rows number: method 1
with RowNumCTE AS (
    SELECT *,
    ROW_NUMBER() OVER(
    PARTITION BY ParcelID,
    PropertyAddress,
    SalePrice,
    SaleDate,
    LegalReference
    ORDER BY ParcelID
    ) row_num
FROM dbo.housing
)
SELECT * FROM RowNumCTE
where row_num >1

-- find duplicates rows number: method 2
SELECT ParcelID, PropertyAddress,SalePrice,LegalReference, SaleDate,COUNT(*)
FROM dbo.housing
GROUP BY ParcelID, PropertyAddress,SalePrice,LegalReference,SaleDate
HAVING COUNT(*)>1

-- Remove Duplicates
with RowNumCTE AS (
    SELECT *,
    ROW_NUMBER() OVER(
    PARTITION BY ParcelID,
    PropertyAddress,
    SalePrice,
    SaleDate,
    LegalReference
    ORDER BY ParcelID
    ) row_num
FROM dbo.housing
)
DELETE
FROM RowNumCTE
where row_num >1
-- Duplicates removed!

------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- remove unused columns

SELECT * from dbo.housing

ALTER TABLE dbo.housing
DROP COLUMN OwnerAddress, PropertyAddress, TaxDistrict, SaleDate

