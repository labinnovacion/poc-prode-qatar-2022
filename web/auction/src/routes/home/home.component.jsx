import { Outlet } from "react-router-dom";
const Home = () => {
    return (
        <div>
            <h1>Home Page</h1>
            <Outlet/>
        </div>
    );
};

export default Home;