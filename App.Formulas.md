
    //
    // Named expression / formula 
    //
    // Constant
    //
    // DRY: don't repeat yourself
    //      if you need to update, change it once!
    //
    fxExp_Greeting = "Hello, ";

    fxExp_UsersFullName = gblUserName; 

    
    fxExp_MyYesNoMaybe_Enum = {
        No: "No", 
        Yes: "Yes", 
        Maybe: "Maybe", 
        NotApplicable: "N/A"  
    };

    //
    // one column table/collection
    // with the possible values
    // 
    fxExp_YesNoMaybe_Table = [
        "No", 
        "Yes", 
        "Maybe", 
        "N/A"
    ];

    fxExp_MinWidth = 375; 

    fxExp_Person = {
        FullName: "Darren Neese", 
        Cell: "407-867-5309"
    };

    fxExp_People = [
        {
            FullName: "Darren Neese", 
            Cell: "407-867-5309"
        },
        {
            FullName: "Mark", 
            Cell: "407-555-5555"
        }
    ];


    // ⬆️    Examples of using named expressions
    //          as constants or literals
    //
    //       But they could be variable in nature
    //

    //
    // User-defined Function
    //
    // Get the X or the Y of a control in relation to
    // its parent dimension. 
    // 
    // Understanding the parameters: 
    //   - Pass in width values to get the X value for 'Self'
    //   - Pass in height values to get the Y value for 'Self'   
    //
    fxFun_GetCenteredDimension( ParentDimension:Number, 
                                SelfDimension:Number):Number = (
        (ParentDimension - SelfDimension) / 2
    );
    //
    // You could simply copy/paste this for X value for centered self
    // #️⃣ fxGetCenteredDimension(Parent.Width, Self.Width) 
    // You could simply copy/paste this for Y value for centered self
    // #️⃣ fxGetCenteredDimension(Parent.Height, Self.Height) 

    fxFun_FindArea(AllParameters:fxTyp_Dimensions):Number = (
        AllParameters.ParentiDimension * AllParameters.SelfDimension
    );
    
    fxFun_CreateDimensions(Width:Number, Length:Number):fxTyp_Dimensions = {
        ParentiDimension:Width, 
        SelfDimension:Length
    };

    fxTyp_Dimensions:= Type(
        {
            ParentiDimension:Number, 
            SelfDimension:Number
        }
    );

    fxFun_ProduceValue():Number = 1;

    fxExp_QandA = [
        {ID: 1, Question: "What is 5 + 3?", Answer: "8"},
        {ID: 2, Question: "What is the capital of France?", Answer: "Paris"},
        {ID: 3, Question: "True or False: The sun rises in the west.", Answer: "False"}
    ];