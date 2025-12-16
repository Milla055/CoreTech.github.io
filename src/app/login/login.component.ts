import { Component, DestroyRef, EventEmitter, inject, OnInit, Output } from '@angular/core';
import {
  AbstractControl,
  FormControl,
  FormGroup,
  ReactiveFormsModule,
  Validators,
} from '@angular/forms';
import { RouterLink} from '@angular/router';
import { debounceTime, of } from 'rxjs';
import { AuthService } from '../services/auth.service';

@Component({
  selector: 'app-login',
  imports: [ReactiveFormsModule, RouterLink],
  templateUrl: './login.component.html',
  styleUrl: './login.component.css',
})
export class LoginComponent implements OnInit {
  @Output() cancel = new EventEmitter<void>();
  private destroyRef = inject(DestroyRef);
  private AuthService = inject(AuthService);
  form = new FormGroup({
    email: new FormControl('', {
      validators: [Validators.email, Validators.required],
    }),
    password: new FormControl('', {
      validators: [Validators.required,],
    }),
  });
  router: any;

  get emailIsInvalid() {
    return (
      this.form.controls.email.touched &&
      this.form.controls.email.dirty &&
      this.form.controls.email.invalid
    );
  }

  get passwordIsInvalid() {
    return (
      this.form.controls.password.touched &&
      this.form.controls.password.dirty &&
      this.form.controls.password.invalid
    );
  }

  ngOnInit() {
    const savedForm = window.localStorage.getItem('saved-login-form');

    if(savedForm) {
      const loadedForm = JSON.parse(savedForm);
      this.form.patchValue({
        email: loadedForm.email
      })
    }

    const subscription = this.form.valueChanges.pipe(debounceTime(500)).subscribe({
      next: (value) => {
        window.localStorage.setItem('saved-login-form', JSON.stringify({ email: value.email }));
      },
    });

    this.destroyRef.onDestroy(() => subscription.unsubscribe());
  }

  closeLogin() {
    this.cancel.emit();
  }

  onSubmit() {
    if (this.form.invalid) return;
    const finalData = {email:this.form.value.email!, password:this.form.value.password!}

    this.AuthService.login(finalData).subscribe({
      next: (result) => {
        console.log(result);
        localStorage.setItem('JWT', result.token!);
        this.router.navigate(['/mainpage']);
      },
      error: (err) => {
        console.error('Hiba történt:', err);
        alert('Hibás email vagy jelszó');
      }
    });
  }
  //TODO login fetch


}

