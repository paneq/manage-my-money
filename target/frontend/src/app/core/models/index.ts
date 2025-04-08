export interface User {
    id: number;
    username: string;
    email: string;
    role: string;
    createdAt: Date;
    updatedAt: Date;
}

export interface AuthResponse {
    token: string;
    user: User;
}

export interface ApiResponse<T> {
    data: T;
    message: string;
    status: number;
}