import { Outlet } from "react-router-dom";

const Auction = () => {
    return(
        <div>
            <h1>Auction Page</h1>
            <Outlet/>
        </div>
    );
}

export default Auction;