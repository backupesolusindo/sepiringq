<?php
defined('BASEPATH') OR exit('No direct script access allowed');

class Login extends CI_Controller{

  public function __construct()
  {
    parent::__construct();
    // $this->load->model("ModelUser");
  }

  function index()
  {
    $this->load->view('Login/login');
  }

  function cek_login(){
    $username = $this->input->post("username");
    $password = $this->input->post("password");
    $cek = $this->db->get_where("user",array("username"=>$username,"jabatan"=>"Admin"));
    if ($cek->num_rows()>0) {
      $user = $cek->row_array();
      $pw_valid = $user['password'];

      if (password_verify($password, $pw_valid)) {
        $data_session = array(
          'id_user' => $user['id_user'],
          'nama' => $user['nama'],
          'username' => $user['username'],
        );
        $this->session->set_userdata($data_session);
        redirect(base_url()."Index");
      } else {
        // Password salah, tampilkan alert
        echo "<script>alert('Password Anda Salah');</script>";
        redirect(base_url()."Login");
      }
    } else {
      $this->session->set_flashdata("salah_username", "Username Tidak Ditemukan");
      redirect(base_url()."Login");
    }
}


  function logout(){
    $data_session = array('iduser','user','username',);
    $this->session->unset_userdata($data_session);
    redirect(base_url()."Login");
  }
}
