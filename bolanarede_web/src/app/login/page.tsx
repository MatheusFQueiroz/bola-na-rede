'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Goal } from 'lucide-react';
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
  CardDescription,
} from '@/components/ui/card';
import { Label } from '@/components/ui/label';
import { api } from '@/lib/api';
import { setToken, setSession } from '@/lib/auth';

const loginSchema = z.object({
  email: z.string().email('Email inválido'),
  password: z.string().min(1, 'Senha obrigatória'),
});

type LoginForm = z.infer<typeof loginSchema>;

interface JwtPayload {
  id?: string;
  sub?: string;
  name?: string;
  displayName?: string;
  email?: string;
}

export default function LoginPage() {
  const router = useRouter();
  const [error, setError] = useState<string | null>(null);

  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<LoginForm>({
    resolver: zodResolver(loginSchema),
  });

  const onSubmit = async (data: LoginForm) => {
    setError(null);
    try {
      const response = await api.post('/v1/auth/login', data);
      const token: string =
        (response.data as { accessToken?: string }).accessToken ??
        (response.data as { data?: { accessToken?: string } }).data?.accessToken ?? '';

      if (!token) {
        setError('Resposta inválida do servidor');
        return;
      }

      // Decode JWT payload (base64url → JSON)
      const payloadBase64 = token.split('.')[1];
      const payload: JwtPayload = JSON.parse(
        atob(payloadBase64.replace(/-/g, '+').replace(/_/g, '/'))
      );

      setToken(token);
      setSession({
        userId: payload.id ?? payload.sub ?? '',
        displayName: payload.displayName ?? payload.name ?? payload.email ?? '',
        email: payload.email ?? '',
      });

      router.push('/fields');
    } catch (err: unknown) {
      const axiosError = err as { response?: { data?: { message?: string } } };
      const message = axiosError?.response?.data?.message;
      setError(message ?? 'Email ou senha incorretos');
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center p-4 bg-sidebar">
      <Card className="w-full max-w-sm shadow-2xl">
        <CardHeader className="text-center items-center pb-2">
          <div className="mb-3 flex h-14 w-14 items-center justify-center rounded-2xl bg-primary/10 ring-1 ring-primary/20">
            <Goal className="h-8 w-8 text-primary" />
          </div>
          <CardTitle className="text-xl">BolaNaRede</CardTitle>
          <CardDescription>Painel do Dono de Campo</CardDescription>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit(onSubmit)} className="flex flex-col gap-4">
            <div className="flex flex-col gap-1.5">
              <Label htmlFor="email">Email</Label>
              <Input
                id="email"
                type="email"
                placeholder="seu@email.com"
                {...register('email')}
              />
              {errors.email && (
                <p className="text-xs text-destructive">{errors.email.message}</p>
              )}
            </div>

            <div className="flex flex-col gap-1.5">
              <Label htmlFor="password">Senha</Label>
              <Input
                id="password"
                type="password"
                placeholder="••••••••"
                {...register('password')}
              />
              {errors.password && (
                <p className="text-xs text-destructive">{errors.password.message}</p>
              )}
            </div>

            {error && <p className="text-sm text-destructive">{error}</p>}

            <Button type="submit" disabled={isSubmitting} className="w-full">
              {isSubmitting ? 'Entrando...' : 'Entrar'}
            </Button>
          </form>
        </CardContent>
      </Card>
    </div>
  );
}
