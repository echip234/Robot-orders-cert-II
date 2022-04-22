*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Browser.Selenium    auto_close=${FALSE}
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.Archive
Library           OperatingSystem
Library           RPA.Robocorp.Vault
Library           RPA.Dialogs

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${ordersURL}=    Collect Query From User
    Log    ${ordersURL}
    Open the robot order website
    ${orders}    Get orders    ${ordersURL}
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts
    [Teardown]    Close the Browser

*** Keywords ***
Fill the form
    [Arguments]    ${row}
    Select From List By Value    id:head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    css:input[placeholder="Enter the part number for the legs"]    ${row}[Legs]
    Input Text    id:address    ${row}[Address]

Open the robot order website
    ${secret}=    Get Secret    main_site
    Open Available Browser    ${secret}[URL]    maximized=True    headless=True
    #Maximize Browser Window

Get orders
    [Arguments]    ${ordersURL}
    Download    ${ordersURL}    overwrite=True
    ${orders}    Read table from CSV    orders.csv    header=True
    [Return]    ${orders}

Close the annoying modal
    Click Button When Visible    css:.btn-dark

Preview the robot
    Click Button    preview

Submit the order
    FOR    ${i}    IN RANGE    50
        ${present}=    Run Keyword And Return Status    Element Should Be Visible    id=order
        Run Keyword If    ${present}    Click Button    order
        Exit For Loop If    ${present} == False
    END

Go to order another robot
    Click Button    order-another

Store the receipt as a PDF file
    [Arguments]    ${row}
    Wait Until Element Is Visible    id:receipt
    ${receipt_results_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_results_html}    ${OUTPUT_DIR}${/}temp/receipt${row}.pdf
    [Return]    ${OUTPUT_DIR}${/}temp/receipt${row}.pdf

Take a screenshot of the robot
    [Arguments]    ${row}
    Wait Until Element Is Visible    css:#robot-preview-image
    Scroll Element Into View    css:.attribution
    Screenshot    css:#robot-preview-image    ${OUTPUT_DIR}${/}temp/robot-image${row}.jpg
    [Return]    ${OUTPUT_DIR}${/}temp/robot-image${row}.jpg

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Add Watermark Image To Pdf    image_path=${screenshot}    source_path=${pdf}    output_path=${pdf}

Create a ZIP file of the receipts
    Remove File    ${OUTPUT_DIR}${/}temp/*.jpg    #remove jpg's no longer needed and not included in zip file
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}${/}PDFs.zip
    Archive Folder With Zip
    ...    ${OUTPUT_DIR}${/}temp
    ...    ${zip_file_name}
    Empty Directory    ${OUTPUT_DIR}${/}temp    #remove temp files no longer needed

Collect Query From User
    Add text input    file    label=Please enter the URL of the orders CSV file
    ${ordersURL}=    Run dialog
    [Return]    ${ordersURL.file}

Close the Browser
    Close Browser
