export interface loginRequest{
    email: string,
    password: string
}

export interface loginResponse{
    status: string,
    statusCode: number,
    token: string
}

export interface registerRequest{
    email: string,
    username: string,
    password: string,
    phone: string,
    marketing?: boolean
}

export interface registerResponse{
    status: string,
    statusCode: number
}