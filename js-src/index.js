import ReactDOM from 'react-dom'
import React from 'react';
import MainController from './MainController'
import Q from 'q'

window.addEventListener('load', _ => ReactDOM.render(<MainController />, document.getElementById('main')));