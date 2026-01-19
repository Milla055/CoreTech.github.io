export interface loginRequest{
    email: string,
    password: string
}

export interface loginResponse{
    status: string,
    statusCode: number,
    accessToken: string,
    refreshToken: string,
    username: string
}

export interface registerRequest{
    email: string,
    username: string,
    password: string,
    phone: string,
}

export interface registerResponse{
    status: string,
    statusCode: number
}