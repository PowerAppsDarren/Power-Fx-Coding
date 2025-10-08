Use Case : Button On Select 
1. Update a global variable named CurrentItem with the currently selected item from a Gallery control named Gallery1.
2. Then, navigate the user to a screen named "EditScreen".

Code Algorithm 

Set(CurrentItem, Gallery1.Selected);
Navigate(EditScreen, Transition.Fade, { SelectedTitle: Gallery1.Selected.Title, SelectedID: Gallery1.Selected.ID })