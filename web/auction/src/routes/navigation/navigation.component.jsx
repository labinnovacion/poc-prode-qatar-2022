import { Fragment } from 'react';
import { Outlet } from 'react-router-dom';
import { ReactComponent as LinkLogo } from '../../assets/crown.svg';

import {
    NavigationContainer,
    LogoContainer,
    NavLinks,
    NavLink
} from './navigation.styles';

const Navigation = () => {
    
    return (
        <Fragment>
            <NavigationContainer>
                <LogoContainer to='/'>
                    <LinkLogo className='logo'/>
                </LogoContainer>
                <NavLinks>
                    <NavLink to='/auction'>
                        SUBASTA
                    </NavLink>
                    <NavLink to='/auth'>
                        SIGN IN
                    </NavLink>
                </NavLinks>
            </NavigationContainer>
            <Outlet/>
        </Fragment>
    );
};

export default Navigation;