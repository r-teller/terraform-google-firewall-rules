import React from 'react';
import ReactDOM from 'react-dom';
import './index.css';
// Assuming the file is still named App.js but the exported component is now PageMain
import PageMain from './App'; // Change this line to import PageMain

//import * as serviceWorker from './serviceWorker';

ReactDOM.render(<PageMain />, document.getElementById('root')); // Use PageMain here

// If you want your app to work offline and load faster, you can change
// unregister() to register() below. Note this comes with some pitfalls.
// Learn more about service workers: https://bit.ly/CRA-PWA
//serviceWorker.unregister();