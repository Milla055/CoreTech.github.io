export interface loginRequest{
    email: string,
    password: string
}

export interface loginResponse{
    userId: number,  // User ID from backend
    role: string,
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
    statusCode: number,
    username: string,
}