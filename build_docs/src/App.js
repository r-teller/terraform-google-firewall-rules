
import React from 'react';
import './App.css';

import { Typography, Paper, Container } from "@mui/material";


import CloudVPN from "./Schema/CloudVPN";

function PageMain() {
    return (
        <div className="App">
            <header className="App-header">
                <Typography component={'h1'} variant={'h6'}>
                    Firewall Rules JSON Generator v2
                </Typography>
            </header>
            <Container className="App-main" maxWidth={'md'} fixed>
                <Paper style={{ margin: 16, padding: 24 }}>
                    <CloudVPN />
                </Paper>
            </Container>
        </div>
    );
}

export default PageMain;
