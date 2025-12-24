<?php
defined('BASEPATH') or exit('No direct script access allowed');

class Login extends REST_Controller
{
    public function __construct()
    {
        parent::__construct();
        // $this->load->model("ModelAuth");
    }

    public function login_post()
    {
        $username = $this->post("username");
        $password = $this->post("password");
    
        // Check if a user with the given username exists
        $user = $this->db->get_where("user", array('username' => $username))->row();
    
        if ($user) {
            $hashedPasswordFromDatabase = $user->password;
    
            // Verify password
            if (password_verify($password, $hashedPasswordFromDatabase)) {
                unset($user->password);
                // Successful login
                //$this->session->set_userdata('user_logged_in', true);
                $data = $user;
                $message = array(
                    'status' => 200,
                    'message' => "OK"
                );
            } else {
                // Incorrect password
                $data = null;
                $message = array(
                    'status' => 401,
                    'message' => "Password salah"
                );
            }
        } else {
            // User not found
            $data = null;
            $message = array(
                'status' => 404,
                'message' => "Username salah"
            );
        }
    
        $this->response(array('response' => $data, 'message' => $message));
    }
}