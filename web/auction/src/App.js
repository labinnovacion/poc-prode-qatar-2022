// import logo from './logo.svg';
import {Routes, Route} from 'react-router-dom';

import Navigation from './routes/navigation/navigation.component';
import Home from './routes/home/home.component';
import Auction from './routes/auction/auction.component';

import './App.css';

const Authentication = () => {
  return(
    <div>
      <h1>Authentication Page</h1>
    </div>
  )
};

const Checkout = () => {
  return(
    <div>
      <h1>Checkout Page</h1>
    </div>
  );
};

const App = () => {
  return (
    <Routes>
    <Route path='/' element={<Navigation/>}>
      <Route index element={<Home/>}/>
      <Route path='auction' element={<Auction/>}/>
      <Route path='auth' element={<Authentication/>}/>
      <Route path='checkout' element={<Checkout/>}/>
    </Route>
  </Routes>
  );
}

export default App;
