<?php

defined('BASEPATH') or exit('No direct script access allowed');

require APPPATH . 'libraries/REST_Controller.php';

/**
 * This is an example of a few basic user interaction methods you could use
 * all done with a hardcoded array
 *
 * @package         CodeIgniter
 * @subpackage      Rest Server
 * @category        Controller
 * @author          Phil Sturgeon, Chris Kacerguis
 * @license         MIT
 * @link            https://github.com/chriskacerguis/codeigniter-restserver
 */

class User extends REST_Controller
{

  /* authendicate user */

  // constructor
  public function __construct()
  {
    parent::__construct();
    //$this->load->model("ModelAuth");
  }

  public function coba_get()
  {
    $data = null;
    $message = array(
      'status' => 204,
      'message' => "Coba Berhasil"
    );
    $this->response(array('response' => $data, 'message' => $message));
  }

  public function list_user_post()
  {
    $table = 'users'; //nama tabel dari database
    $column_order = array(null, 'id', 'username', 'first_name', 'email'); //field yang ada di table user
    $column_search = array('id', 'username', 'first_name', 'last_name', 'email'); //field yang diizin untuk pencarian
    $order = array('id' => 'desc'); // default order

    $list = $this->datatable->get_datatables($table, $column_order, $column_search, $order);
    $data = array();
    $no = $this->post('start');
    foreach ($list as $field) {
      $no++;
      $row = array();
      $row[] = $this->mmanage->no($field->id, $no);
      $row[] = $field->username;
      $row[] = $field->first_name;
      $row[] = $field->email;
      $row[] = $this->mmanage->edit($field->id);
      $data[] = $row;
    }

    $output = array(
      "draw" => $this->post('draw'),
      "recordsTotal" => $this->datatable->count_all(),
      "recordsFiltered" => $this->datatable->count_filtered(),
      "data" => $data,
    );
    //output dalam format JSON
    $this->response($output);
  }

  public function datauser_get()
  {
    $id = $this->input->get("iddata_user");
    $data_user = $this->db->get_where("data_user", array('iddata_user' => $id));
    if ($data_user->num_rows() > 0) {
      $data = $data_user->row_array();
      $message = array(
        'status' => 200,
        'message' => "OK",
        'count'   => $data_user->num_rows(),
      );
    } else {
      $data = null;
      $message = array(
        'status' => 204,
        'message' => "NO_CONTENT"
      );
    }
    $this->response(array('response' => $data, 'message' => $message));
  }

  public function profil_get()
  {
    $id = $this->input->get("id_data_user");
    $data_user = $this->db->get_where("data_user", array('iddata_user' => $id));
    if ($data_user->num_rows() > 0) {
      $data = $data_user->row_array();
      $message = array(
        'status' => 200,
        'message' => "OK",
        'count'   => $data_user->num_rows(),
      );
    } else {
      $data = null;
      $message = array(
        'status' => 204,
        'message' => "NO_CONTENT"
      );
    }
    $this->response(array('response' => $data, 'message' => $message));
  }

  public function update_profil_put()
  {
    $id = $this->put("id_data_user");
    $data = array(
      'nama' => $this->put("nama"),
      'email' => $this->put("email"),
      'telp' => $this->put("telp"),
      'jekel' => $this->put("jekel"),
      'alamat' => $this->put("alamat"),
      'update_on' => date("Y-m-d H:i:s"),

    );
    $this->db->where("iddata_user", $id);
    if ($this->db->update("data_user", $data)) {
      $message = array(
        'status' => 200,
        'message' => "OK"
      );
    } else {
      $message = array(
        'status' => 500,
        'message' => "INTERNAL_SERVER_ERROR"
      );
    }
    // $data['id'] = $id;
    $this->response(array('response' => $data, 'message' => $message));
  }

  public function login_post()
  {
    $username = $this->post("username");
    $password = $this->post("password");
    $cek = $this->db
      ->select("data_user.iddata_user, data_user.no_anggota, data_user.nama, data_user.status_anggota, data_user.pusat_idpusat,
      data_user.status_mitra, mitra.idmitra,
      user.password, user.username")
      ->join("data_user", "data_user.iddata_user=user.data_user_iddata_user")
      ->join("mitra", "mitra.data_user_iddata_user = data_user.iddata_user", "left")
      ->where("username", $username)
      ->or_where("data_user.no_anggota", $username)
      ->or_where("data_user.email", $username)
      ->get("user");
    if ($cek->num_rows() > 0) {
      $user = $cek->row_array();
      $pw_valid = $user['password'];
      // die(var_dump($pw_valid));
      if (password_verify($password, $pw_valid)) {
        unset($user['password']);
        unset($user['roles']);
        unset($user['CREATE_ON']);
        unset($user['UPDATE_ON']);
        // unset($user['data_user_iddata_user']);
        $data = $user;
        $message = array(
          'status' => 200,
          'message' => "OK"
        );
      } else {
        $data = null;
        $message = array(
          'status' => 401,
          'message' => "UNAUTHORIZED"
        );
      }
    } else {
      $data = null;
      $message = array(
        'status' => 204,
        'message' => "NO_CONTENT"
      );
    }
    $this->response(array('response' => $data, 'message' => $message));
  }

  public function login_kurir_post()
  {
    $username = $this->post("username");
    $password = $this->post("password");
    $cek = $this->db
      ->join("data_user", "data_user.iddata_user=user.data_user_iddata_user")
      ->join("kurir", "kurir.idkurir=user.idkurir")
      ->where("username", $username)
      ->or_where("data_user.no_anggota", $username)
      ->get("user");
    if ($cek->num_rows() > 0) {
      $user = $cek->row_array();
      $pw_valid = $user['password'];
      // die(var_dump($pw_valid));
      if (password_verify($password, $pw_valid)) {
        $data = $user;
        $message = array(
          'status' => 200,
          'message' => "OK"
        );
      } else {
        $data = null;
        $message = array(
          'status' => 401,
          'message' => "UNAUTHORIZED"
        );
      }
    } else {
      $data = null;
      $message = array(
        'status' => 204,
        'message' => "NO_CONTENT"
      );
    }
    $this->response(array('response' => $data, 'message' => $message));
  }

  public function login_mitra_post()
  {
    $username = $this->post("username");
    $password = $this->post("password");
    $cek = $this->db
      ->join("data_user", "data_user.iddata_user=user.data_user_iddata_user")
      ->join("mitra", "mitra.data_user_iddata_user = data_user.iddata_user")
      ->get_where("user", array("username" => $username));
    if ($cek->num_rows() > 0) {
      $user = $cek->row_array();
      $pw_valid = $user['password'];
      // die(var_dump($pw_valid));
      if (password_verify($password, $pw_valid)) {
        unset($user['password']);
        unset($user['roles']);
        unset($user['CREATE_ON']);
        unset($user['UPDATE_ON']);
        // unset($user['data_user_iddata_user']);
        $data = $user;
        $message = array(
          'status' => 200,
          'message' => "OK"
        );
      } else {
        $data = null;
        $message = array(
          'status' => 401,
          'message' => "Password Anda Salah!"
        );
      }
    } else {
      $data = null;
      $message = array(
        'status' => 204,
        'message' => "User Tidak Ditemukan / Tidak Terdaftar"
      );
    }
    $this->response(array('response' => $data, 'message' => $message));
  }

  public function daftar_post()
  {
    $noanggota = $this->post("no_anggota");
    $status_anggota = "0";
    if (strlen($noanggota) > 5) {
      $status_anggota = "1";
    }
    // echo strlen($noanggota);
    $this->db->like("nama_pusat", $this->post("wilayah"));
    $wilayah = $this->db->get("pusat")->row_array();
    $data = array(
      'no_anggota' => $noanggota,
      'status_anggota' => $status_anggota,
      'nama' => $this->post("nama"),
      'email' => $this->post("email"),
      'telp' => $this->post("telp"),
      'jekel' => $this->post("jekel"),
      'alamat' => $this->post("alamat"),
      'create_on' => date("Y-m-d H:i:s"),
      'pusat_idpusat' => $wilayah['idpusat'],
    );

    if ($this->db->get_where("user", array('username' => $this->post("username")))->num_rows() < 1) {
      if ($this->db->get_where("data_user", array('email' => $this->post("email")))->num_rows() < 1) {
        if ($this->db->insert('data_user', $data)) {
          $id = $this->db->insert_id();
          $username = $this->post("username");
          $pass = $this->post('password');
          $roles = "user";
          $data2 = array(
            'username'    => $username,
            'password' => password_hash($pass, PASSWORD_DEFAULT, array("cost" => 10)),
            'data_user_iddata_user' => $id,
            'roles'   => json_encode($roles)
          );
          $this->db->insert("user", $data2);
          $data['id'] = $id;
          $message = array(
            'status' => 200,
            'message' => "OK"
          );
        } else {
          $message = array(
            'status' => 500,
            'message' => "INTERNAL_SERVER_ERROR"
          );
        }
      } else {
        $message = array(
          'status' => 502,
          'message' => "Email Sudah Digunakan"
        );
      }
    } else {
      $message = array(
        'status' => 501,
        'message' => "Username Sudah Digunakan"
      );
    }
    $this->response(array('response' => $data, 'message' => $message));
  }

  public function wilayah_get()
  {
    $data = $this->db->get("pusat")->result();
    if (!empty($data)) {
      $message = array(
        'status' => 200,
        'message' => "OK"
      );
    } else {
      $message = array(
        'status' => 204,
        'message' => "NO_CONTENT"
      );
    }
    $this->response(array('response' => $data, 'message' => $message));
  }

  public function reset_password_put()
  {

    $id = $this->put("id_data_user");
    $pass = $this->put("new_password");
    $data = array(
      'password' => password_hash($pass, PASSWORD_DEFAULT, array("cost" => 10)),
    );
    $this->db->where("data_user_iddata_user", $id);
    if ($this->db->update('user', $data)) {
      $message = array(
        'status' => 200,
        'message' => "OK"
      );
    } else {
      $message = array(
        'status' => 500,
        'message' => "INTERNAL_SERVER_ERROR"
      );
    }
    $this->response(array('response' => null, 'message' => $message));
  }
}
